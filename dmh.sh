#!/bin/sh

VERSION="beta 1"
BUILD="0807.1"
CRON_FILE="/opt/var/spool/cron/crontabs/root"
COLUNS="`stty -a | awk -F"; " '{print $3}' | grep "columns" | awk -F" " '{print $2}'`"

function headLine	#1 - заголовок	#2 - скрыть полосу под заголовком	#3 - добавить пустые строки для прокрутки
	{
	if [ -n "$3" ];then
		local COUNTER=24
		while [ "$COUNTER" -gt "0" ];do
			echo -e "\033[30m█\033[39m"
			local COUNTER=`expr $COUNTER - 1`
		done
	fi
	if [ "`expr $COLUNS / 2 \* 2`" -lt "$COLUNS" ];then
		local WIDTH="`expr $COLUNS / 2 \* 2`"
		local PREFIX=' '
	else
		local WIDTH=$COLUNS
		local PREFIX=""
	fi
	if [ -n "$1" ];then
		clear
		local TEXT=$1
		local LONG=`echo ${#TEXT}`
		local SIZE=`expr $WIDTH - $LONG`
		local SIZE=`expr $SIZE / 2`
		local FRAME=`awk -v i=$SIZE 'BEGIN { OFS=" "; $i=" "; print }'`
		if [ "`expr $LONG / 2 \* 2`" -lt "$LONG" ];then
			local SUFIX=' '
		else
			local SUFIX=""
		fi
		echo -e "\033[30m\033[47m$PREFIX$FRAME$TEXT$FRAME$SUFIX\033[39m\033[49m"
	else
		echo -e "\033[30m\033[47m`awk -v i=$COLUNS 'BEGIN { OFS=" "; $i=" "; print }'`\033[39m\033[49m"
	fi
	if [ -n "$MODE" -a -n "$1" -a -z "$2" ];then
		local LONG=`echo ${#MODE}`
		local SIZE=`expr $COLUNS - $LONG - 1`
		echo "`awk -v i=$SIZE 'BEGIN { OFS=" "; $i=" "; print }'`$MODE"
	elif [ -z "$MODE" -a -n "$1" -a -z "$2" ];then
		echo ""
	fi
	}

function showText	#1 - текст	#2 - цвет
	{
	local TEXT=`echo "$1" | awk '{gsub(/\\\t/,"____")}1'`
	local TEXT=`echo -e "$TEXT"`
	local STRING=""
	local SPACE=""
	IFS=$' '
	for WORD in $TEXT;do
			local WORD_LONG=`echo ${#WORD}`
			local STRING_LONG=`echo ${#STRING}`
			if [ "`expr $WORD_LONG + $STRING_LONG + 1`" -gt "$COLUNS" ];then
				echo -e "$2$STRING\033[39m\033[49m" | awk '{gsub(/____/,"    ")}1'
				local STRING=$WORD
			else
				local STRING=$STRING$SPACE$WORD
				local SPACE=" "
			fi
	done
	echo -e "$2$STRING\033[39m\033[49m" | awk '{gsub(/____/,"    ")}1'
	}

function messageBox	#1 - текст	#2 - цвет
	{
	local TEXT=$1
	local COLOR=$2
	local LONG=`echo ${#TEXT}`
	if [ ! "$LONG" -gt "`expr $COLUNS - 4`" ];then
		local TEXT="│ $TEXT │"
		local LONG=`echo ${#TEXT}`
		local SIZE=`expr $COLUNS - $LONG`
		local SIZE=`expr $SIZE / 2`
		local SPACE=`awk -v i=$SIZE 'BEGIN { OFS=" "; $i=" "; print }'`
		local LONG=`expr $LONG - 4`
		local LEFT_UP='┌'
		local RIGHT_UP='┐'
		local LEFT_DOWN='└'
		local RIGHT_DOWN='┘'
	else
		local LONG=`expr $COLUNS - 4`
		local SPACE=""
		local LEFT_UP='□'
		local RIGHT_UP='□'
		local LEFT_DOWN='□'
		local RIGHT_DOWN='□'
	fi
	if [ "$COLUNS" = "80" ];then
		echo -e "$COLOR$SPACE$LEFT_UP─`awk -v i=$LONG 'BEGIN { OFS="─"; $i="─"; print }'`─$RIGHT_UP\033[39m\033[49m"
		echo -e "$COLOR$SPACE$TEXT\033[39m\033[49m"
		echo -e "$COLOR$SPACE$LEFT_DOWN─`awk -v i=$LONG 'BEGIN { OFS="─"; $i="─"; print }'`─$RIGHT_DOWN\033[39m\033[49m"
	else
		echo -e "$COLOR$SPACE□-`awk -v i=$LONG 'BEGIN { OFS="-"; $i="-"; print }'`-□\033[39m\033[49m"
		echo -e "$COLOR$SPACE$TEXT\033[39m\033[49m"
		echo -e "$COLOR$SPACE□-`awk -v i=$LONG 'BEGIN { OFS="-"; $i="-"; print }'`-□\033[39m\033[49m"
	fi
	}

function copyRight	#1 - название	#2 - год
	{
	if [ "`date +"%C%y"`" -gt "$2" ];then
		local YEAR="-`date +"%C%y"`"
	fi
	local COPYRIGHT="© $2$YEAR rino Software Lab."
	local SIZE=`expr $COLUNS - ${#1} - ${#VERSION} - ${#COPYRIGHT} - 3`
	read -t 1 -n 1 -r -p " $1 $VERSION`awk -v i=$SIZE 'BEGIN { OFS=" "; $i=" "; print }'`$COPYRIGHT" keypress
	}

function scriptSetup	#1 - скрыть вариант "выход" из меню накопителей
	{
	LIST=`ndmc -c show interface | sed 's/^[ ]*//' | grep '^id: \|^description: \|^address: ' | grep -B 2 '^address: ' | grep '^id: \|^description: \|^address: ' | grep -A 1 '^id: Bridge' | sed -e "s/^id: /id: @@/g;s/^description: /description: \\t/g" | awk -F": " '{print $2}' | sed ':a;N;$!ba;s/\n//g' | sed -e "s/@@/\\n/g" | grep -v '^$'`
	if [ -z "$LIST" ];then
		messageBox "Сегменты - отсутствуют." "\033[91m"
		echo ""
		exit
	fi
	SEGMENTS=`echo "$LIST" | awk '{print NR":\t"$0}'`
	echo "Выбор сегментов:"
	echo ""
	showText "\tВыберите один (или несколько, через пробел) идентификаторов сегментов сети (в которых должен быть доступен DLNA-сервер)..."
	echo ""
	echo "$SEGMENTS" | awk -F"\t" '{print "\t"$1, $3}'
	if [ -z "$1" ];then
		echo -e "\t0: Выход (по умолчанию)"
	fi
	echo ""
	read -r -p "Ваш выбор:"
	echo ""
	if [ "$REPLY" = "0" -a -z "$1" -o -z "$REPLY" -a -z "$1" ];then
		headLine
		copyRight "DMh" "2025"
		clear
		rm -rf $0
		exit
	fi
	REPLY=`echo "$REPLY" | tr ' ' '\n'`
	REPLY=`echo "$SEGMENTS" | grep "^\$REPLY:"`
	if [ -n "$REPLY" ];then
		TEXT=`echo "$REPLY" | awk -F"\t" '{print "\tndmc -c dlna interface "$2}'`
	else
		messageBox "Сегмент не выбран." "\033[91m"
		echo ""
		exit
	fi
	echo -e "#!/bin/sh\n\nexport LD_LIBRARY_PATH=/lib:/usr/lib:$LD_LIBRARY_PATH\nif [ ! \"\`ndmc -c show dlna | sed 's/^[ ]*//' | grep '^running: ' | awk -F\": \" '{print \$2}'\`\" = \"yes\" ];then\n$TEXT\n\tndmc -c system configuration save\n\tlogger \"DMh: настройки DLNA-сервера - исправлены.\"\nfi" > /opt/etc/ndm/wan.d/dmh.sh
	chmod 755 /opt/etc/ndm/wan.d/dmh.sh
	messageBox "Настройка завершена."
	echo ""
	read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	echo ""
	}

function scriptDelete
	{
	echo "Удаление DLNA Mesh helper..."
	echo ""
	rm -rf /opt/etc/ndm/wan.d/dmh.sh
	messageBox "Скрипт - удалён."
	echo ""
	read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	echo ""
	rm -rf $0
	}

function mainMenu
	{
	headLine "DLNA Mesh helper"
	if [ -f "/opt/etc/ndm/wan.d/dmh.sh" ];then
			showText "Обнаружен настроенный скрипт."
			echo ""
			echo -e "\t1: Новая конфигурация"
			echo -e "\t2: Удалить скрипт"
			echo -e "\t0: Выход (по умолчанию)"
			echo ""
			read -r -p "Ваш выбор:"
			echo ""
			if [ "$REPLY" = "1" ];then
				scriptSetup "no exit"
			elif [ "$REPLY" = "2" ];then
				scriptDelete
			fi
	else
		scriptSetup
	fi
	headLine
	copyRight "DMh" "2025"
	clear
	rm -rf $0
	exit
	}

echo;while [ -n "$1" ];do
case "$1" in

-v)	echo "$0 $VERSION build $BUILD"
	exit
	;;

*)	headLine "DLNA Mesh helper"
	messageBox "Введён некорректный ключ." "\033[91m"
	echo ""
	echo "Доступные ключи:"
	showText "\t-v: Отображение текущей версии DMh"
	echo ""
	exit
	;;
	
esac;shift;done

mainMenu
