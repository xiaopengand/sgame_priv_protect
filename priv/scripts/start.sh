#!/system/bin/sh

ip_site="https://2021.ipchaxun.com/"
process_num_file="/data/priv/.process_num"
local_config="/data/priv/local.config"
local_string="$(cat ${local_config})"
proc_name="com.tencent.tmgp.sgame"
kit_file="/data/priv/config/Kitsunebi"
v2ray_file="/data/priv/config/v2rayNG"
freeze_proxy_app="/data/priv/config/freeze_proxy_app"
freeze_self="/data/priv/config/freeze_self"

validate_ip() {
  # 查询 IP 并且输出到 ip.log
  find_ip="$(echo $(curl -s -m 10 ${ip_site}) | grep ${local_string})"
  if [ -n "${find_ip}" ]; then
    return 1
  fi
  return 0
}

start_proxy() {
  if [ -f "${kit_file}" ]; then
    pm enable fun.kitsunebi.kitsunebi4android >/dev/null 2>&1
    am start fun.kitsunebi.kitsunebi4android/.ui.StartVpnActivity >/dev/null 2>&1
    return 1
  elif [ -f "${v2ray_file}" ]; then
    pm enable com.v2ray.ang >/dev/null 2>&1
    am start "intent:#Intent;launchFlags=0x1000c000;component=com.v2ray.ang/.ui.ScSwitchActivity;end" >/dev/null 2>&1
    #am start com.v2ray.ang/.ui.ScSwitchActivity
    return 1
  fi
  
  return 0
}

handle_sgame_start() {
  local_string="$(cat ${local_config})"
  if [ ! -n "${local_string}" ]; then
    return 0
  fi
  start_proxy
  success_start_proxy=$?
  if [ $success_start_proxy -gt 0 ]; then
    sleep 3
  fi
  validate_ip
  ip_valid=$?
  if [ ! $ip_valid -eq 1 ]; 
  then
    am force-stop com.tencent.tmgp.sgame
  fi
}

handle_sgame_stop() {
  freeze_proxy
  freeze_self
  delete_sgame_pref_file
}

freeze_proxy() {
  if [[ -f "$freeze_proxy_app" &&  -f "${kit_file}" ]]; then
    pm disable fun.kitsunebi.kitsunebi4android >/dev/null 2>&1
  elif [[ -f "$freeze_proxy_app" &&  -f "${v2ray_file}" ]]; then
    pm disable com.v2ray.ang >/dev/null 2>&1
  fi
}

freeze_self() {
  if [[ -f "$freeze_self" ]]; then
    pm disable com.tencent.tmgp.sgame >/dev/null 2>&1
  fi
}

delete_sgame_pref_file() {
  rm -rf /data/data/com.tencent.tmgp.sgame/shared_prefs/.xg.vip.settings.xml.xml
  rm -rf /data/data/com.tencent.tmgp.sgame/shared_prefs/device_id.vip.xml
  rm -rf /data/data/com.tencent.tmgp.sgame/shared_prefs/igame_priority_sdk_pref_temp_info.xml
  rm -rf /data/data/com.tencent.tmgp.sgame/shared_prefs/igame_priority_sdk_pref_wzry_info.xml
  rm -rf /data/data/com.tencent.tmgp.sgame/shared_prefs/tgpa.xml
}


echo 开始运行
echo '0' >${process_num_file}
# 查询应用状态
while true; do
  pre_process_num="$(cat ${process_num_file})"
  # 查询进程数
  process_num="$(ps -ef | grep -w ${proc_name} | grep -v grep | wc -l)"
  echo "${process_num}" >${process_num_file}
  if [ ${process_num} -gt ${pre_process_num} ]; then
    handle_sgame_start
  elif [[ ${process_num} -lt ${pre_process_num} && ${process_num} -le 2 ]]; then
    handle_sgame_stop
  fi
  sleep 1
done

echo 结束运行
