#!/bin/sh

VERSION="beta 1"
BUILD='0722.1'
CONFIG_FILE='/opt/bin/ps.conf'
DOT="1.1.1.1:	Cloudflare
8.8.8.8:	Google
77.88.8.8:	Яndex"
echo "`ndmc -c components list`" > /dev/null 
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

function showCentered	#1 - текст	#2 - цвет
	{
	if [ "`expr $COLUNS / 2 \* 2`" -lt "$COLUNS" ];then
		local WIDTH="`expr $COLUNS / 2 \* 2`"
		local PREFIX=' '
	else
		local WIDTH=$COLUNS
		local PREFIX=""
	fi
	if [ -n "$1" ];then
		local TEXT=$1
		local LONG=`echo ${#TEXT}`
		if [ "$LONG" -lt "$COLUNS" ];then
			local SIZE=`expr $WIDTH - $LONG`
			local SIZE=`expr $SIZE / 2`
			if [ ! "$COLUNS" -lt "$LONG" ];then
				local SPACE=`awk -v i=$SIZE 'BEGIN { OFS=" "; $i=" "; print }'`
			else
				local SPACE=""
			fi
			if [ "`expr $LONG / 2 \* 2`" -lt "$LONG" ];then
				local SUFIX=' '
			else
				local SUFIX=""
			fi
			echo -e "$2$PREFIX$SPACE$TEXT\033[39m\033[49m"
		else
			local LONG="`expr $LONG / 2`"
			local STRING=""
			local SPACE=""
			IFS=$' '
			for WORD in $TEXT;do
				local WORD_LONG=`echo ${#WORD}`
				local STRING_LONG=`echo ${#STRING}`
				if [ "`expr $WORD_LONG + $STRING_LONG + 1`" -gt "$LONG" ];then
					local SIZE=`expr $COLUNS - $STRING_LONG`
					local SIZE=`expr $SIZE / 2`
					local INDENT=`awk -v i=$SIZE 'BEGIN { OFS=" "; $i=" "; print }'`
					echo -e "$2$INDENT$STRING\033[39m\033[49m"
					local STRING=$WORD
					local END=""
				else
					local STRING=$STRING$SPACE$WORD
					local SPACE=" "
					local END="show"
				fi
			done
			if [ -n "$END" ];then
				local STRING_LONG=`echo ${#STRING}`
				local SIZE=`expr $COLUNS - $STRING_LONG`
				local SIZE=`expr $SIZE / 2`
				local INDENT=`awk -v i=$SIZE 'BEGIN { OFS=" "; $i=" "; print }'`
				echo -e "$2$INDENT$STRING\033[39m\033[49m"
			fi
		fi
	fi
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

function sshFix
	{
	local TEXT=`cat /opt/etc/init.d/S51dropbear`
	if [ -z "`echo "$TEXT" | grep '^PIDFILE="/var/run/dropbear.pid"$'`" ];then
		local TEXT=`echo "$TEXT" | sed "s/^PIDFILE=/PIDFILE=\"\/var\/run\/dropbear.pid\"\n#PIDFILE=/g"`
		echo -e "$TEXT" > /opt/etc/init.d/S51dropbear
	fi
	}

function configSave
	{
	echo -e "COMPONENTS=$COMPONENTS\nSETTINGS=$SETTINGS\nACTION=$ACTION\nAUTO=$AUTO" > $CONFIG_FILE
	}

function configGet
	{
	if [ -f "$CONFIG_FILE" ];then
		local CONFIG=`cat $CONFIG_FILE`
		COMPONENTS=`echo "$CONFIG" | grep "COMPONENTS=" | awk -F"=" '{print $2}'`
		SETTINGS=`echo "$CONFIG" | grep "SETTINGS=" | awk -F"=" '{print $2}'`
		ACTION=`echo "$CONFIG" | grep "ACTION=" | awk -F"=" '{print $2}'`
		AUTO=`echo "$CONFIG" | grep "AUTO=" | awk -F"=" '{print $2}'`
	else
		messageBox "Файл конфигурации - отсутствует." "\033[91m"
		echo ""
		exit
	fi
	}

function configRemove	#1 - автоматический режим
	{
	if [ -f "$CONFIG_FILE" ];then
		rm -rf $CONFIG_FILE
		if [ -z "$1" ];then
			messageBox "Файл конфигурации - удалён."
			echo ""
		fi
	else
		if [ -z "$1" ];then
			messageBox "Файл конфигурации - отсутствует." "\033[91m"
			echo ""
		fi
	fi
	}

function componentsCurent
	{
	echo "`ndmc -c show version | sed 's/^[ ]*//' | sed -n '/^components: /,/^$/p' | sed ':a;N;$!ba;s/\n//g' | sed -e "s/components: //g" | tr ',' '\n' | grep -v '^$' | sort`"
	}

function componentsAll
	{
	echo "`ndmc -c components list | sed 's/^[ ]*//'  | sed -n '/^component: /,/^name: /p' | grep '^name: ' | awk -F": " '{print $2}' | sort`"
	}

function componentsUnavailable
	{
	local ALL=`componentsAll | awk '{print "^"$0"$"}'`
	echo "$COMPONENTS" | sed -e "s/,/\\n/g" | grep -v "$ALL"
	}

function components	#1 - автоматический режим
	{
	if [ -n "$COMPONENTS" ];then
		local CURENT=`componentsCurent | awk '{print "^"$0"$"}'`
		local UNAVAILABLE=`componentsUnavailable`
		local LIST=`echo "$COMPONENTS" | sed -e "s/,/\\n/g" | grep -v "$CURENT"`
		if [ -n "$UNAVAILABLE" ];then
			local FILTER=`echo "$UNAVAILABLE" | awk '{print "^"$0"$"}'`
			local LIST=`echo "$LIST" | grep -v "$FILTER"`
			showText "Следующие компоненты - недоступны для вашего интернет-центра:" "\033[91m"
			echo "$UNAVAILABLE" | awk '{print "\t• "$0}'
			echo ""
		fi
		if [ -n "$LIST" ];then
			if [ -z "$1" ];then
				echo "Будут установлены следующие компоненты:"
			fi
			IFS=$'\n'
			for LINE in $LIST;do
				echo "`ndmc -c components instal $LINE`" > /dev/null
				if [ -z "$1" ];then
					echo -e "\t• $LINE"
				fi
			done
			if [ -z "$1" ];then
				echo ""
			fi
			if [ -z "$1" ];then
				showText "\tНа следующем шаге - интернет-центр будет перезагружен, что разорвёт его связь с терминалом."
			else
				showText "\tЧерез несколько секунд, связи с интернет центром будет разорвана..."
			fi
			showText "\tДля продолжения настройки - необходимо: повторно подключиться к entware (после того как интернет-центр полностью загрузится), при появлении в терминале приглашения на ввод команд (~ #) - нужно ввести: prs и нажать ввод."
			echo ""
			if [ -z "$1" ];then
				read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
				echo ""
				showCentered "Через несколько секунд, связи с интернет центром будет разорвана..."
			fi
			configSave
			echo "`ndmc -c components commit`" > /dev/null
			exit
		else
			messageBox "Все необходимые компоненты - уже установлены."
			echo ""
		fi
	fi
	}

function componentsCheck
	{
	local CURENT=`componentsCurent | awk '{print "^"$0"$"}'`
	local UNAVAILABLE=`componentsUnavailable`
	local LIST=`echo "$COMPONENTS" | sed -e "s/,/\\n/g" | grep -v "$CURENT"`
	if [ -n "$UNAVAILABLE" ];then
		local FILTER=`echo "$UNAVAILABLE" | awk '{print "^"$0"$"}'`
		local LIST=`echo "$LIST" | grep -v "$FILTER"`
	fi
	if [ -n "$LIST" ];then
		messageBox "Установлены не все доступные компоненты." "\033[91m"
		echo ""
		showText "\tВозможно задействовано слишком много компонентов. Попробуйте отключить неиспользуемые, и после перезагрузки - запустить скрипт предварительной настройки с ключом \"-c\" (prs -c)..."
		exit
	fi
	}

function dotGet
	{
	echo "`ndmc -c show dns-proxy | sed 's/^[ ]*//' | sed -n '/^server-tls:/,/^$/p' | grep "^address:" | sort -u | awk -F": " '{print $2}'`"
	}

function dotSetup	#1 - автоматический режим
	{
	IFS=$'\n'
	for LINE in $DOT;do
		local ADDRESS=`echo "$LINE" | awk -F":\t" '{print $1}'`
		if [ -z "$1" ];then
			local NAME=`echo "$LINE" | awk -F":\t" '{print $2}'`
			showText "Добавить прокси-сервер DoT: $NAME?"
			echo ""
			echo -e "\t1: Да"
			echo -e "\t0: Нет (по умолчанию)"
			echo ""
			read -r -p "Ваш выбор:"
			echo ""
		else
			REPLY="1"
		fi
		if [ "$REPLY" = "1" ];then
			echo "`ndmc -c dns-proxy tls upstream $ADDRESS`" > /dev/null
			if [ -z "$1" ];then
				messageBox "Прокси-сервер DoT: $NAME - добавлен."
				echo ""
			fi
		fi
		
	done
	echo "`ndmc -c system configuration save`" > /dev/null
	}

function dnsSetup	#1 - автоматический режим
	{
	local CURENT=`dotGet`
	if [ -z "$CURENT" ];then
		dotSetup "$1"
	elif [ -n "$1" ];then
		local FILTER=`dotGet | awk '{print "^"$0":"}'`
		DOT=`echo "$DOT" | grep -v "$FILTER"`
		dotSetup "$1"
	else
		messageBox "В конфигурации уже есть прокси-серверы DNS-over-TLS."
		echo ""
	fi
	}

function settings	#1 - автоматический режим
	{
	if [ -n "$SETTINGS" ];then
		local LIST=`echo "$SETTINGS" | tr ',' '\n'`
		IFS=$'\n'
		for LINE in $LIST;do
			local EXECUTE=`echo $LINE'Setup'`
			$EXECUTE "$1"
		done
	fi
	}

function allDone	#1 - автоматический режим
	{
	if [ -z "$1" ];then
		showCentered "Настройка интернет-центра - завершена." "\033[92m"
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	fi
	}

function action
	{
	if [ -n "$ACTION" ];then
		$ACTION
		showText "\tВ дальнейшем для запуска скрипта - достаточно будет набрать в терминале: $ACTION и нажать ввод..."
		rm -rf "$0"
	fi
	}

echo;while [ -n "$1" ];do
case "$1" in

-a)	MODE="-a"
	headLine "pre-Setup"
	echo "Список доступных компонентов:"
	echo ""
	componentsAll | awk '{print "\t• "$0}'
	echo ""
	exit
	;;

-c)	MODE="-c"
	headLine "pre-Setup"
	configGet
	components "$AUTO"
	exit
	;;

-D)	MODE="-D"
	headLine "pre-Setup"
	echo "Настройка DNS:"
	echo ""
	dnsSetup
	exit
	;;

-f)	MODE="-f"
	headLine "pre-Setup"
	COMPONENTS=$2
	SETTINGS=$3
	ACTION=$4
	AUTO="auto"
	components "$AUTO"
	settings "$AUTO"
	allDone "$AUTO"
	configRemove "auto"
	action
	exit
	;;

-i)	MODE="-i"
	headLine "pre-Setup"
	echo "Список установленных компонентов:"
	echo ""
	componentsCurent | awk '{print "\t• "$0}'
	echo ""
	exit
	;;

-r)	MODE="-r"
	headLine "pre-Setup"
	echo "Удаление..."
	echo ""
	configRemove
	rm -rf "$0"
	exit
	;;

-s)	MODE="-s"
	headLine "pre-Setup"
	configGet
	settings "$AUTO"
	exit
	;;

-t)	MODE="-t"
	sshFix
	headLine "pre-Setup"
	COMPONENTS=$2
	SETTINGS=$3
	ACTION=$4
	showText "\tДанный инструмент - проверит наличие всех необходимых компонентов операционной системы вашего интернет-центра (при необходимости - установит недостающие и выполнит настройку некоторых параметров)..."
	echo ""
	echo -e "     Ввод: Автоматическая настройка"
	echo -e "\t1: Ручная настройка"
	echo -e "\t0: Выход"
	echo ""
	read -r -p "Ваш выбор:"
	echo ""
	if [ -z "$REPLY" ];then
		AUTO="auto"
		components "$AUTO"
		settings "$AUTO"
		allDone "$AUTO"
		configRemove "auto"
		action
	elif [ "$REPLY" = "1" ];then
		AUTO=""
		components
		settings
		allDone
		configRemove "auto"
		action
	else
		headLine
		copyRight "prS" "2025"
		clear
		exit
	fi
	exit
	;;

-v)	echo "$0 $VERSION build $BUILD"
	exit
	;;

*)	headLine "pre-Setup"
	messageBox "Введён некорректный ключ." "\033[91m"
	echo ""
	echo "Доступные ключи:"
	showText "\t-a: Список доступных компонентов"
	showText "\t-c: Дополнительная попытка установки компонентов"
	showText "\t-D: Настройка DNS"
	showText "\t-f \"компоненты\" \"настройки\" \"команда\": Пропустить диалог и перейти к автоматической установке"
	showText "\t-i: Список установленных компонентов"
	showText "\t-r: Удаление prS"
	showText "\t-s: Дополнительная попытка изменения настроек"
	showText "\t-t \"компоненты\" \"настройки\" \"команда\": Установить компоненты, изменить настройки и выполнить команду"
	showText "\t-v: Отображение текущей версии pS"
	echo ""
	exit
	;;
	
esac;shift;done

headLine "pre-Setup"
configGet
componentsCheck
settings "$AUTO"
allDone "$AUTO"
configRemove "auto"
action