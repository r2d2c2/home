#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
app_dir=/opt/home-app
health_url=http://127.0.0.1:9090/actuator/health
[[ -d "$app_dir" && -w "$app_dir" ]] || {
    echo 'Run sudo bash ops/setup-server.sh on this Jenkins node first.' >&2; exit 1;
}
exec 9>"$app_dir/.deploy.lock"
flock -n 9 || { echo 'Another deployment is running.' >&2; exit 1; }
shopt -s nullglob
jars=()
for jar in build/libs/*.jar; do
    [[ "$jar" == *-plain.jar ]] || jars+=("$jar")
done
[[ ${#jars[@]} -eq 1 ]] || { echo 'Expected exactly one executable JAR.' >&2; exit 1; }

healthy() {
    local attempt
    for attempt in {1..45}; do
        if systemctl is-active --quiet home.service &&
            curl --fail --silent --show-error --connect-timeout 2 --max-time 3 "$health_url" 2>/dev/null |
            python3 -c 'import json,sys; sys.exit(0 if json.load(sys.stdin).get("status") == "UP" else 1)' 2>/dev/null; then
            return 0
        fi
        sleep 2
    done
    return 1
}

had_previous=false
if [[ -f "$app_dir/home.jar" ]]; then
    cp -- "$app_dir/home.jar" "$app_dir/home.jar.previous"
    had_previous=true
fi
install -m 0644 "${jars[0]}" "$app_dir/home.jar.next"
mv -f -- "$app_dir/home.jar.next" "$app_dir/home.jar"
if sudo -n /usr/bin/systemctl restart home.service && healthy; then
    echo 'Deployment succeeded: home.service is UP on port 9090.'
    exit 0
fi

echo 'Deployment failed. Check: sudo journalctl -u home.service -n 100' >&2
if "$had_previous"; then
    cp -- "$app_dir/home.jar.previous" "$app_dir/home.jar.next"
    mv -f -- "$app_dir/home.jar.next" "$app_dir/home.jar"
    if sudo -n /usr/bin/systemctl restart home.service && healthy; then
        echo 'Previous JAR restored successfully.' >&2
    else
        echo 'Previous JAR restored, but service recovery failed.' >&2
    fi
else
    sudo -n /usr/bin/systemctl stop home.service
fi
exit 1
