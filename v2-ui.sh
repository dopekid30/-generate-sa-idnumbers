#!/bin/bash
#Setup

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}ERROR: ${plain} This script must run as root user！\n" && exit 1

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -p "$1 [Default$2]: " temp
        if [[ x"${temp}" == x"" ]]; then
            temp=$2
        fi
    else
        read -p "$1 [y/n]: " temp
    fi
    if [[ x"${temp}" == x"y" || x"${temp}" == x"Y" ]]; then
        return 0
    else
        return 1
    fi
}

confirm_restart() {
    confirm "Whether to restart the panel, restarting the panel will also restart v2ray" "y"
    if [[ $? == 0 ]]; then
        restart
    else
        show_menu
    fi
}

before_show_menu() {
    echo && echo -n -e "${yellow}Press enter to return to the main menu: ${plain}" && read temp
    show_menu
}

install() {
    bash <(curl -Ls https://blog.sprov.xyz/v2-ui.sh)
    if [[ $? == 0 ]]; then
        if [[ $# == 0 ]]; then
            start
        else
            start 0
        fi
    fi
}

update() {
    confirm "This function will forcibly reinstall the current latest version without data loss. Do you want to continue?" "n"
    if [[ $? != 0 ]]; then
        echo -e "${red}Cancelled${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 0
    fi
    bash <(curl -Ls https://blog.sprov.xyz/v2-ui.sh)
    if [[ $? == 0 ]]; then
        echo -e "${green}The update is complete and the panel has been automatically restarted${plain}"
        exit
    fi
}

uninstall() {
    confirm "Are you sure you want to uninstall the panel, v2ray will also uninstall?" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    systemctl stop v2-ui
    systemctl disable v2-ui
    rm /etc/systemd/system/v2-ui.service -f
    systemctl daemon-reload
    systemctl reset-failed
    rm /etc/v2-ui/ -rf
    rm /usr/local/v2-ui/ -rf

    echo ""
    echo -e "The uninstallation is successful. If you want to delete this script, exit the script and run ${green}rm /usr/bin/v2-ui -f${plain} Delete"

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

reset_user() {
    confirm "Are you sure you want to reset the username and password to admin" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    /usr/local/v2-ui/v2-ui resetuser
    echo -e "Username and password have been reset to ${green}admin${plain}，Now please restart the panel"
    confirm_restart
}

reset_config() {
    confirm "Are you sure you want to reset all panel settings? Account data will not be lost, username and password will not be changed" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    /usr/local/v2-ui/v2-ui resetconfig
    echo -e "All panels have been reset to default values, now please restart the panels and use the default ${green}65432${plain} Port access panel"
    confirm_restart
}

set_port() {
    echo && echo -n -e "Enter port number[1-65535]: " && read port
    if [[ -z "${port}" ]]; then
        echo -e "${yellow}Cancelled${plain}"
        before_show_menu
    else
        /usr/local/v2-ui/v2-ui setport ${port}
        echo -e "After setting the port, please restart the panel and use the newly set port ${green}${port}${plain} Access panel"
        confirm_restart
    fi
}

start() {
    check_status
    if [[ $? == 0 ]]; then
        echo ""
        echo -e "${green}The panel is already running, no need to start again, if you need to restart, please select restart${plain}"
    else
        systemctl start v2-ui
        sleep 2
        check_status
        if [[ $? == 0 ]]; then
            echo -e "${green}v2-ui Start successfully${plain}"
        else
            echo -e "${red}The panel failed to start. It may be because the start time has exceeded two seconds. Please check the log information${plain}"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

stop() {
    check_status
    if [[ $? == 1 ]]; then
        echo ""
        echo -e "${green}The panel has stopped, no need to stop again${plain}"
    else
        systemctl stop v2-ui
        sleep 2
        check_status
        if [[ $? == 1 ]]; then
            echo -e "${green}v2-ui Stop with v2ray successfully${plain}"
        else
            echo -e "${red}The panel failed to stop. It may be because the stop time exceeds two seconds. Please check the log information${plain}"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

restart() {
    systemctl restart v2-ui
    sleep 2
    check_status
    if [[ $? == 0 ]]; then
        echo -e "${green}v2-ui Restart successfully with v2ray${plain}"
    else
        echo -e "${red}Panel restart failed, it may be because the startup time exceeds two seconds, please check the log information${plain}"
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

status() {
    systemctl status v2-ui -l
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

enable() {
    systemctl enable v2-ui
    if [[ $? == 0 ]]; then
        echo -e "${green}v2-ui Set the power-on auto-start successfully${plain}"
    else
        echo -e "${red}v2-ui Failed to set auto start${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

disable() {
    systemctl disable v2-ui
    if [[ $? == 0 ]]; then
        echo -e "${green}v2-ui Cancel the startup success${plain}"
    else
        echo -e "${red}v2-ui Cancel startup failure${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_log() {
    echo && echo -n -e "Many WARNING logs may be output during the use of the panel. If there is nothing wrong with the use of the panel, there is no problem. Press Enter to continue: " && read temp
    tail -500f /etc/v2-ui/v2-ui.log
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

install_bbr() {
    bash <(curl -L -s https://github.com/sprov065/blog/raw/master/bbr.sh)
    if [[ $? == 0 ]]; then
        echo ""
        echo -e "${green}Successfully installed bbr${plain}"
    else
        echo ""
        echo -e "${red}Failed to download the bbr installation script, please check whether the machine can connect to Github${plain}"
    fi

    before_show_menu
}

update_shell() {
    wget -O /usr/bin/v2-ui -N --no-check-certificate https://github.com/sprov065/v2-ui/raw/master/v2-ui.sh
    if [[ $? != 0 ]]; then
        echo ""
        echo -e "${red}Failed to download the script, please check whether the machine can connect to Github${plain}"
        before_show_menu
    else
        chmod +x /usr/bin/v2-ui
        echo -e "${green}The upgrade script is successful, please rerun the script${plain}" && exit 0
    fi
}

# 0: running, 1: not running, 2: not installed
check_status() {
    if [[ ! -f /etc/systemd/system/v2-ui.service ]]; then
        return 2
    fi
    temp=$(systemctl status v2-ui | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ x"${temp}" == x"running" ]]; then
        return 0
    else
        return 1
    fi
}

check_enabled() {
    temp=$(systemctl is-enabled v2-ui)
    if [[ x"${temp}" == x"enabled" ]]; then
        return 0
    else
        return 1;
    fi
}

check_uninstall() {
    check_status
    if [[ $? != 2 ]]; then
        echo ""
        echo -e "${red}The panel has been installed, please do not install repeatedly${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

check_install() {
    check_status
    if [[ $? == 2 ]]; then
        echo ""
        echo -e "${red}Please install the panel first${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

show_status() {
    check_status
    case $? in
        0)
            echo -e "Panel status: ${green}Running${plain}"
            show_enable_status
            ;;
        1)
            echo -e "Panel status: ${yellow}Not running${plain}"
            show_enable_status
            ;;
        2)
            echo -e "Panel status: ${red}Not Installed${plain}"
    esac
    show_v2ray_status
}

show_enable_status() {
    check_enabled
    if [[ $? == 0 ]]; then
        echo -e "Panel boot: ${green}YES${plain}"
    else
        echo -e "Panel boot: ${red}NO${plain}"
    fi
}

check_v2ray_status() {
    count=$(ps -ef | grep "v2ray-v2-ui" | grep -v "grep" | wc -l)
    if [[ count -ne 0 ]]; then
        return 0
    else
        return 1
    fi
}

show_v2ray_status() {
    check_v2ray_status
    if [[ $? == 0 ]]; then
        echo -e "v2ray status: ${green}Running${plain}"
    else
        echo -e "v2ray status: ${red}Not running${plain}"
    fi
}

show_usage() {
    echo "v2-ui Management Script: "
    echo "------------------------------------------"
    echo "v2-ui              - more functions"
    echo "v2-ui start        - start panel"
    echo "v2-ui stop         - stop panel"
    echo "v2-ui restart      - restart panel"
    echo "v2-ui status       - panel status"
    echo "v2-ui enable       - enable panel"
    echo "v2-ui disable      - disable panel"
    echo "v2-ui log          - panel log"
    echo "v2-ui update       - panel update"
    echo "v2-ui install      - panel install"
    echo "v2-ui uninstall    - panel uninstall"
    echo "------------------------------------------"
}

show_menu() {
    echo -e "
  ${green}v2-ui Panel Script${plain}
--- https://t.me/joash_singh ---
  ${green}0.${plain} Exit script
———————————————————
  ${green}1.${plain} Install v2-ui
  ${green}2.${plain} Update v2-ui
  ${green}3.${plain} Uninstall v2-ui
———————————————————
  ${green}4.${plain} Reset Login
  ${green}5.${plain} Reset Settings
  ${green}6.${plain} Set Panel Port
———————————————————
  ${green}7.${plain} Start v2-ui
  ${green}8.${plain} Stop v2-ui
  ${green}9.${plain} Reboot v2-ui
 ${green}10.${plain} V2-ui Status
 ${green}11.${plain} V2-ui Log
———————————————————
 ${green}12.${plain} Enable Boot 
 ${green}13.${plain} Disable Boot
 ${green}14.${plain} Install bbr
 ———————————————————
 "
    show_status
    echo && read -p "Enter Option[0-14]: " num

    case "${num}" in
        0) exit 0
        ;;
        1) check_uninstall && install
        ;;
        2) check_install && update
        ;;
        3) check_install && uninstall
        ;;
        4) check_install && reset_user
        ;;
        5) check_install && reset_config
        ;;
        6) check_install && set_port
        ;;
        7) check_install && start
        ;;
        8) check_install && stop
        ;;
        9) check_install && restart
        ;;
        10) check_install && status
        ;;
        11) check_install && show_log
        ;;
        12) check_install && enable
        ;;
        13) check_install && disable
        ;;
        14) install_bbr
        ;;
        *) echo -e "${red}Please enter the correct number [0-14]${plain}"
        ;;
    esac
}


if [[ $# > 0 ]]; then
    case $1 in
        "start") check_install 0 && start 0
        ;;
        "stop") check_install 0 && stop 0
        ;;
        "restart") check_install 0 && restart 0
        ;;
        "status") check_install 0 && status 0
        ;;
        "enable") check_install 0 && enable 0
        ;;
        "disable") check_install 0 && disable 0
        ;;
        "log") check_install 0 && show_log 0
        ;;
        "update") check_install 0 && update 0
        ;;
        "install") check_uninstall 0 && install 0
        ;;
        "uninstall") check_install 0 && uninstall 0
        ;;
        *) show_usage
    esac
else
    show_menu
fi
