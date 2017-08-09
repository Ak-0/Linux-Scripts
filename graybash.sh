#!/bin/bash
#Bash Script
#Ak_0
#8-9/2017



#colors
Black='\e[0;30m'
White='\e[0;37m'
BBlack='\e[1;30m'
BWhite='\e[1;37m'
On_Black='\e[40m'
On_White='\e[47m'
NC="\e[m"



clear
/bin/echo -e ${Black}${On_White}"
------------------------\n------------------------
Hello, This script should help you change your Bash Prompt colors 
to greyscale themes for the user account "${White}"`whoami`"${Black}${On_White}".
------------------------\n------------------------\n"${NC}


/bin/echo -e ${Black}${On_White}"
Please Select what you want to do.
------------------------
1. Set Default Bash Prompt.
2. Set Custom Bash Prompts.
------------------------"

read action
clear
if [ $action == 1 ]; then
	echo " You selected to set the default Prompt."

elif [ $action == 2 ]; then

/bin/echo -e ${Black}${On_White}"
Please Select whhat prompt you want to use.
------------------------"${NC}
/bin/echo -e "1." ${White}">["${BBlack}" `whoami`@02:23:52 "${White}"]:/usr/local/src:$"${NC}
/bin/echo -e "2." "["${BBlack}${On_Black}"14:23"${NC}"]/usr/local/src>"
/bin/echo -e "3." ""
/bin/echo -e "4." ""
/bin/echo -e ${Black}${On_White}"
------------------------"${NC}
	function makeBkup
	{	
				if [ ! -f ./bashrc.bkup.orig ]; then
							cp ~/.bashrc ./bashrc.bkup.orig
							echo "\nBash Backup Created!\n"
				fi
						return 1	
	}
	read option
	
		case $option in 
			1)
				makeBkup
				bash  --rcfile <(echo "PS1='>[ \[$(tput sgr0)\]\[\033[38;5;241m\]\u\[$(tput sgr0)\]\[\033[38;5;15m\]@\[$(tput sgr0)\]\[\033[38;5;8m\]\@\[$(tput sgr0)\]\[\033[38;5;15m\] ]:\w:\\$\[$(tput sgr0)\]'") -i
				clear
		;;
			2)
				makeBkup
				 bash --rcfile <(echo " PS1='[\[$(tput sgr0)\]\[\033[38;5;246m\]\A\[$(tput sgr0)\]\[\033[38;5;15m\]]\w\[$(tput bold)\]\[$(tput sgr0)\]\[\033[38;5;243m\]>\[$(tput sgr0)\]'") -i
				clear
		;;
		esac

else 
		echo "you did not select a valid response"

fi



	
	



		
