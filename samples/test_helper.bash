
unset_openstack_env() {
  for v in $(env | grep OS_ | sed -e "s/\(.*\)=.*/\1/g") ; do  unset $v ; done
}

delete_all_floating_ip() {
  for ip in $(openstack floating ip list | awk '/\| [a-f0-9]/{ print $2 }') ; do
    openstack floating ip delete ${ip}
  done
}

allocate_4_floating_ip() {
  for ip in {1..4} ; do
    openstack floating ip create ${OS_FLOATING_IP_POOL}
  done
}

title() {
  {
    echo ""
    echo "###########################################################"
    echo "### $1"
    echo "###########################################################"
    echo ""  
  } >> $BATS_OUT_LOG
}

flush_out() {
  {
    echo ""
    printf "%s\n" "${lines[@]}"
  } >> $BATS_OUT_LOG
}
