#!/bin/bash

if [ $(dialog | grep -c "ComeOn Dialog!") -eq 0 ]; then
  sudo apt install dialog
fi
if [ -f joinin.conf ]; then
  touch joinin.conf
fi

# add default value to joinin config if needed
if ! grep -Eq "^RPCoverTor=" joinin.conf; then
  echo "RPCoverTor=off" >> joinin.conf
fi

if grep -Eq "^rpc_host = .*.onion" /home/joinmarket/.joinmarket/joinmarket.cfg; then 
  echo "RPC over Tor is on"
  sudo sed -i "s/^RPCoverTor=.*/RPCoverTor=on/g" joinin.conf
else
  echo "RPC over Tor is off"
  sudo sed -i "s/^RPCoverTor=.*/RPCoverTor=off/g" joinin.conf
fi

source /home/joinmarket/joinin.conf

# cd ~/bin/joinmarket-clientserver && source jmvenv/bin/activate && cd scripts

# BASIC MENU INFO
HEIGHT=26
WIDTH=52
CHOICE_HEIGHT=20
BACKTITLE=""
TITLE="JoininBox"
MENU="Choose from the options:"
OPTIONS=()
BACKTITLE="JoininBox GUI"

# Basic Options
OPTIONS+=(\
  INFO "Show the address list and balance" \
  GEN "Generate a new wallet" \
  IMPORT "Copy wallet(s) from a remote node"\
  RECOVER "Restore a wallet from the seed" \
  "" ""
  MAKER "Run the Yield Generator" \
  YG_CONF "Configure the Yield Generator" \
  MONITOR "Monitor the YG service" \
  YG_LIST "List the past YG activity"\
  STOP "Stop the YG service" \
  "" ""
  HISTORY "Show all past transactions" \
  OBWATCH "Watch the offer book locally" \
  #EMPTY "Empty a mixdepth" \
  "" ""
  CONFIG "Edit the joinmarket.cfg" \
  UPDATE "Update the JoininBox scripts and menu" \
  X "Exit to the Command Line" \
  #PAY "Pay to an address using coinjoin" \
  #TUMBLER "Run the Tumbler to mix quickly" \
)

CHOICE=$(dialog --clear \
                --backtitle "$BACKTITLE" \
                --title "$TITLE" \
                --menu "$MENU" \
                $HEIGHT $WIDTH $CHOICE_HEIGHT \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)

case $CHOICE in

        INFO)
            /home/joinmarket/start.script.sh wallet-tool
            echo ""
            echo "Fund the wallet on addresses labeled 'new' to avoid address reuse."
            ;;
        PAY)
            ;;            
        TUMBLER)
            ;;
        MAKER)
            /home/joinmarket/get.password.sh
            source /home/joinmarket/joinin.conf
            /home/joinmarket/start.service.sh yg-privacyenhanced $wallet
            echo "Starting the Yield Generator in the background.."
            dialog \
            --title "Monitoring the Yield Generator - press CTRL+C to exit"  \
            --prgbox "sudo journalctl -fn20 -u yg-privacyenhanced" 20 140
            /home/joinmarket/menu.sh
            ;;
        MONITOR)
            dialog \
            --title "Monitoring the Yield Generator - press CTRL+C to exit"  \
            --prgbox "sudo journalctl -fn40 -u yg-privacyenhanced" 40 140
            /home/joinmarket/menu.sh
            /home/joinmarket/menu.sh
            ;;            
        YG_LIST)
            dialog \
            --title "timestamp            cj amount/satoshi  my input count  my input value/satoshi  cjfee/satoshi  earned/satoshi  confirm time/min  notes"  \
            --prgbox "column $HOME/.joinmarket/logs/yigen-statement.csv -t -s ","" 100 140
            /home/joinmarket/menu.sh
            ;;
        HISTORY)
            /home/joinmarket/start.script.sh wallet-tool history
            ;;
        OBWATCH)
            #TODO show hidden service only if already running
            /home/joinmarket/start.ob-watcher.sh
            errorOnInstall=$?
            if [ ${errorOnInstall} -eq 0 ]; then
              TOR_ADDRESS=$(sudo cat /var/lib/tor/ob-watcher/hostname)
              dialog --title "Started the ob-watcher service" \
                --msgbox "\nVisit the address in the Tor Browser:\nhttps://$TOR_ADDRESS" 8 74
            else 
              DIALOGRC=.dialogrc.onerror dialog --title "Error during install" \
                --msgbox "\nPlease search or report at:\n https://github.com/openoms/joininbox/issues" 7 56
            fi
            /home/joinmarket/menu.sh
            ;;
        EMPTY)
            ;;
        YG_CONF)
            /home/joinmarket/set.conf.sh /home/joinmarket/joinmarket-clientserver/scripts/yg-privacyenhanced.py
            /home/joinmarket/menu.sh            
            ;;
        STOP)
            sudo systemctl stop yg-privacyenhanced
            /home/joinmarket/menu.sh
            ;;
        GEN)
            clear
            echo ""
            . /home/joinmarket/joinmarket-clientserver/jmvenv/bin/activate
            if [ ${RPCoverTor} = on ];then 
              torify python /home/joinmarket/joinmarket-clientserver/scripts/wallet-tool.py generate
            else
              python /home/joinmarket/joinmarket-clientserver/scripts/wallet-tool.py generate
            fi
            ;;
        IMPORT) 
            /home/joinmarket/import.wallet.sh
            /home/joinmarket/menu.sh
            ;;
        RECOVER)
            echo ""
            . /home/joinmarket/joinmarket-clientserver/jmvenv/bin/activate
            if [ ${RPCoverTor} = on ];then 
              torify python /home/joinmarket/joinmarket-clientserver/scripts/wallet-tool.py recover
            else
              python /home/joinmarket/joinmarket-clientserver/scripts/wallet-tool.py recover
            fi
            ;;
        CONFIG)
            /home/joinmarket/install.joinmarket.sh
            errorOnInstall=$?
            if [ ${errorOnInstall} -eq 0 ]; then
              dialog --title "Installed JoinMarket" \
                --msgbox "\nContinue from the menu or the command line " 7 56
            else 
              DIALOGRC=.dialogrc.onerror dialog --title "Error during install" \
                --msgbox "\nPlease search or report at:\n https://github.com/openoms/joininbox/issues" 7 56
            fi
            /home/joinmarket/menu.sh
            ;;
        UPDATE)
            ./update.joininbox.sh
            /home/joinmarket/menu.sh
            ;;
        X)
            clear
            echo "***********************************"
            echo "* JoinBox Commandline"
            echo "***********************************"
            echo "Refer to the documentation about how to get started and much more:"
            echo "https://github.com/JoinMarket-Org/joinmarket-clientserver/blob/master/README.md"
            echo ""
            echo "To return to main menu use the command: menu"
            echo ""
            exit 1;
            ;;            
esac
