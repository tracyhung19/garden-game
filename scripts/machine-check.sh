#!/bin/bash
# Zi Garden voice setup: read-only machine check for the family Mac (plan section 2).
# Changes nothing. Prints a report and copies it to the clipboard.
# Leaves out serial numbers, user name and host name.
out(){ printf '%-20s %s\n' "$1" "$2"; }
clt=$(xcode-select -p 2>/dev/null)
ver(){ # version of a tool without triggering Apple's "install developer tools" pop-up
  local p; p=$(command -v "$1" 2>/dev/null) || { echo missing; return; }
  if [ -z "$clt" ] && [ "${p%/*}" = /usr/bin ]; then echo "stub only (needs Command Line Tools)"; return; fi
  case $1 in
    ffmpeg) v=$(ffmpeg -version </dev/null 2>/dev/null | head -1 | awk '{print $3}')
            ffmpeg -hide_banner -encoders </dev/null 2>/dev/null | grep -q libmp3lame && v="$v, mp3 ok" || v="$v, NO mp3 encoder";;
    *) v=$("$1" --version </dev/null 2>&1 | head -1);;
  esac
  echo "${v:-present} [$p]"
}
arm=$(sysctl -n hw.optional.arm64 2>/dev/null); rosetta=$(sysctl -n sysctl.proc_translated 2>/dev/null)
ram=$(( $(sysctl -n hw.memsize) / 1073741824 ))
free=$(df -k "$HOME" | awk 'NR==2{printf "%d",$4/1048576}')
macos=$(sw_vers -productVersion)
ICD="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
{
echo "=== ZI-VOICE MACHINE CHECK v1 ==="
out date "$(date '+%Y-%m-%d %H:%M %Z')"
echo "--- hardware ---"
out apple_silicon "$([ "$arm" = 1 ] && echo yes || echo no)"
out arch_now "$(uname -m)$([ "$rosetta" = 1 ] && echo ' (Terminal is running under Rosetta!)')"
out chip "$(sysctl -n machdep.cpu.brand_string 2>/dev/null)"
out model "$(system_profiler SPHardwareDataType 2>/dev/null </dev/null | awk -F': ' '/Model Name/{print $2;exit}') / $(sysctl -n hw.model 2>/dev/null)"
out ram_gb "$ram"
out cpu_cores "$(sysctl -n hw.ncpu) total, $(sysctl -n hw.perflevel0.physicalcpu 2>/dev/null || echo '?') performance"
out gpu_cores "$(system_profiler SPDisplaysDataType 2>/dev/null </dev/null | awk -F': ' '/Total Number of Cores/{print $2;exit}')"
out macos "$macos ($(sw_vers -buildVersion))"
out disk_free_gb "$free of $(df -k "$HOME" | awk 'NR==2{printf "%d",$2/1048576}')"
echo "--- safety ---"
out power "$(pmset -g batt 2>/dev/null </dev/null | head -1 | sed "s/Now drawing from //;s/'//g")"
out filevault "$(fdesetup status 2>/dev/null </dev/null | head -1)"
out firewall "$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null </dev/null | sed 's/.*Firewall is //')"
out work_managed "$(profiles status -type enrollment 2>/dev/null </dev/null | tr '\n' ' ')"
out icloud_desk_docs "$( { [ -d "$ICD/Desktop" ] || [ -d "$ICD/Documents" ]; } && echo 'probably ON (keep ~/zi-voice out of Desktop/Documents)' || echo 'off or unknown')"
echo "--- tools ---"
out xcode_clt "${clt:-missing}"
for t in brew git git-lfs python3 conda ffmpeg sox docker; do out "$t" "$(ver $t)"; done
echo "--- verdict ---"
if [ "$arm" != 1 ]; then v="INTEL MAC: not recommended, plan a different machine"
elif [ "$ram" -ge 16 ]; then v="APPLE SILICON ${ram}GB: proceed with the plan as written"
else v="APPLE SILICON ${ram}GB: possible, zero-shot only, small batches"; fi
[ "$free" -lt 30 ] && v="$v | LOW DISK: ${free}GB free, need about 30GB"
[ "${macos%%.*}" -lt 13 ] && v="$v | OLD macOS: $macos, 13 or newer recommended"
[ "$rosetta" = 1 ] && v="$v | Terminal under Rosetta: turn off 'Open using Rosetta' for Terminal"
echo "$v"
echo "=== END ==="
} > /tmp/zi-check.txt 2>&1
cat /tmp/zi-check.txt
pbcopy < /tmp/zi-check.txt && echo && echo ">> Report copied to the clipboard. Paste it into the chat with Claude."
