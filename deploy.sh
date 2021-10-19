#!/bin/sh

# UUID="00277430-85b5-46e2-a6c9-4fe3da538187"
# APP_NAME="lyz7805-v2ray"
REGION="hkg"

if ! command -v flyctl >/dev/null 2>&1; then
    curl -L https://fly.io/install.sh | FLYCTL_INSTALL=/usr/local sh
fi

if [ -z "${APP_NAME}" ]; then
    printf '\e[31mPlease set APP_NAME first.\n\e[0m' && exit 1
fi

if [ "$(flyctl info --app "${APP_NAME}" | grep -o "Could not resolve App")" = "Could not resolve App" ]; then
    printf '\e[33mCould not resolve app. Next, create the App.\n\e[0m'
    flyctl apps create "${APP_NAME}"

    if [ "$(flyctl info --app "${APP_NAME}" | grep -o "Could not resolve App")" = "Could not resolve App" ]; then
        printf '\e[32mCreate app success.\n\e[0m'
    else
        printf '\e[31mCreate app failed.\n\e[0m' && exit 1
    fi
else
    printf '\e[33mThe app has been created.\n\e[0m'
fi

printf '\e[33mNext, create app config file - fly.toml.\n\e[0m'
cat <<EOF >./fly.toml
app = "$APP_NAME"

kill_signal = "SIGINT"
kill_timeout = 5

[[services]]
  internal_port = 443
  protocol = "tcp"

  [services.concurrency]
    hard_limit = 25
    soft_limit = 20

  [[services.ports]]
    handlers = ["http"]
    port = "80"

  [[services.ports]]
    handlers = ["tls", "http"]
    port = "443"

  [[services.tcp_checks]]
    grace_period = "1s"
    interval = "15s"
    port = "8080"
    restart_limit = 6
    timeout = "2s"
EOF
printf '\e[32mCreate app config file success.\n\e[0m'
printf '\e[33mNext, set app secrets and regions.\n\e[0m'

flyctl secrets set UUID="${UUID}"
flyctl regions set ${REGION}
printf '\e[32mApp secrets and regions set success. Next, deploy the app .\n\e[0m'
flyctl deploy --detach
# flyctl status --app ${APP_NAME}