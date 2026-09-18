#!/usr/bin/env bash
# Run once with sudo on the application server. Does not start the app.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo 'Run: sudo bash ops/setup-server.sh' >&2; exit 1; }
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
id jenkins >/dev/null
for command in java curl python3 systemctl visudo flock; do
    command -v "$command" >/dev/null
done
java_version=$(/usr/bin/java -XshowSettings:properties -version 2>&1)
[[ "$java_version" =~ java.specification.version\ =\ 25 ]] || {
    echo '/usr/bin/java must use Java 25.' >&2; exit 1;
}
if [[ -e /etc/systemd/system/home.service || -e /usr/lib/systemd/system/home.service ]]; then
    echo 'home.service already exists; review it before installing this service.' >&2
    exit 1
fi
if ! id home-app >/dev/null 2>&1; then
    useradd --system --user-group --home-dir /var/lib/home-app --shell /usr/sbin/nologin home-app
fi
install -d -o home-app -g home-app -m 0750 /var/lib/home-app
install -d -o jenkins -g jenkins -m 0755 /opt/home-app
install -o root -g root -m 0644 home.service /etc/systemd/system/home.service
sudoers_tmp=$(mktemp)
trap 'rm -f "$sudoers_tmp"' EXIT
printf '%s\n' 'jenkins ALL=(root) NOPASSWD: /usr/bin/systemctl restart home.service, /usr/bin/systemctl stop home.service' > "$sudoers_tmp"
visudo -cf "$sudoers_tmp"
install -o root -g root -m 0440 "$sudoers_tmp" /etc/sudoers.d/jenkins-home
systemctl daemon-reload
systemctl enable home.service
echo 'Ready. Jenkins can now deploy to /opt/home-app and restart home.service.'
