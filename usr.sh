#!/bin/sh

VERSION="beta 2"
BUILD="0804.4"
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

function scheduleAdd
	{
	if [ ! -f "$CRON_FILE" ];then
		if [ ! -d "`dirname "$CRON_FILE"`" ];then
			mkdir -p "`dirname "$CRON_FILE"`"
		fi
		echo "" > $CRON_FILE
	fi
	local LIST="`cat $CRON_FILE | grep -v ' usr$\|^$'`"
	echo -e "$LIST\n*/$PERIOD */1 * * * usr\n" > $CRON_FILE
	chmod 644 $CRON_FILE
	touch $CRON_FILE
	}

function scheduleDelete
	{
	if [ -n "`cat $CRON_FILE | grep "usr"`" ];then
		local LIST="`cat $CRON_FILE | grep -v ' usr$\|^$'`"
		echo -e "$LIST\n" > $CRON_FILE
		chmod 644 $CRON_FILE
		touch $CRON_FILE
	fi
	}

function scriptSetup
	{
	LIST=`ls /tmp/mnt`
	if [ -z "$LIST" ];then
		messageBox "USB-накопители - отсутствуют." "\033[91m"
		exit
	fi
	STORAGES=`echo "$LIST" | awk '{print NR":\t"$0}'`
	echo "Выберите накопитель:"
	echo ""
	showText "\tКаждый накопитель в списке – представлен в двух экземплярах (по метке тома и по идентификатору)..."
	echo ""
	echo "$STORAGES" | awk -F"\t" '{print "\t"$1, $2}'
	echo -e "\t0: Выход (по умолчанию)"
	echo ""
	read -r -p "Ваш выбор:"
	echo ""
	if [ "$REPLY" = "0" -o -z "$REPLY" ];then
		headLine
		copyRight "USr" "2025"
		clear
		rm -rf $0
		exit
	fi
	REPLY=`echo "$STORAGES" | grep "^\$REPLY:"`
	if [ -n "$REPLY" ];then
		STORAGE=`echo "$REPLY" | awk -F"\t" '{print $2}'`
		LOG=`echo "$REPLY" | awk -F"\t" '{print "/tmp/mnt/"$2"/usr-log.txt"}'`
	else
		messageBox "Накопитель не выбран." "\033[91m"
		exit
	fi
	LIST=`ls /tmp/mnt/$STORAGE`
	if [ -z "$LIST" ];then
		messageBox "На накопителе отсутствуют файлы и папки." "\033[91m"
		exit
	fi
	TARGETS=`echo "$LIST" | awk '{print NR":\t"$0}'`
	echo "Выберите файл или папку:"
	echo ""
	showText "\tПо наличию доступа к выбранному файлу/папке – будет определяться доступность накопителя..."
	echo ""
	echo "$TARGETS" | awk -F"\t" '{print "\t"$1, $2}'
	echo ""
	read -r -p "Ваш выбор:"
	echo ""
	REPLY=`echo "$TARGETS" | grep "^\$REPLY:"`
	if [ -n "$REPLY" ];then
		TARGET='/tmp/mnt/'$STORAGE/`echo "$REPLY" | awk -F"\t" '{print $2}'`
	else
		messageBox "Файл или папка - не выбран(а)." "\033[91m"
		exit
	fi
	LIST=`ndmc -c show usb | grep 'device: \|manufacturer: \|product: \|port: ' | sed -e "s/device: /device: @@/g; s/manufacturer: /manufacturer:  m=/g; s/product: /product: p=/g; s/port: /port: u=/g" | awk -F": " '{print $2}' | tr '\n' '\t' | sed -e "s/@@/\\n/g" | grep -v '^$'`
	PORTS=""
	IFS=$'\n'
	for LINE in $LIST;do
		SORT=`echo "$LINE" | tr '\t' '\n' | sort | awk -F"=" '{print $2}' | tr '\n' '\t'`
		PORTS="$PORTS\n$SORT"
	done
	PORTS=`echo -e "$PORTS" | sort -t'\t' -k5 | grep -v '^$' | sed -e "s/^\\t//g" | awk '{print NR":"$0}'`
	if [ "`echo "$PORTS" | grep -c $`" = "1" ];then
		REPLY=1
	else
			echo "Выберите USB=порт:"
			echo ""
			showText "\tВыбранный порт будет отключён, при отсутствии доступа к накопителю..."
			echo ""
			echo "$PORTS" | awk -F"\t" '{print "\t"$1" USB "$4" ("$2, $3")"}'
			echo ""
			read -r -p "Ваш выбор:"
			echo ""
	fi
	REPLY=`echo "$PORTS" | grep "^\$REPLY:"`
	if [ -n "$REPLY" ];then
		PORT=`echo "$REPLY" | awk -F"\t" '{print $4}'`
	else
		messageBox "Порт не выбран." "\033[91m"
		exit
	fi
	echo "Укажите период проверки:"
	echo ""
	showText "\tПериод - время в минутах (от 1 до 30), устанавливает временной промежуток (в каждом часу) - между проверками доступности выбранного файла/папки. Если установлено значение 15: проверка будет осуществляться на 0, 15, 30 и 45-ой минуте (каждого часа). Если значение периода - 7: проверка будет выполняться на 0, 7, 14, 21, 28, 35, 42, 49 и 56-ой минуте каждого часа..."
	echo ""
	read -r -p "Период:"
	echo ""
	if [ -n "$REPLY" -a -z "`echo "$REPLY" | sed 's/[0-9]//g'`" ];then
		if [ ! "$REPLY" -gt "30" -a ! "$REPLY" -lt "1" ];then
			PERIOD="$REPLY"
		else
			PERIOD="30"
			messageBox "Установлен период в 30 минут"
			echo ""
		fi
	else
		PERIOD="30"
		messageBox "Установлен период в 30 минут"
		echo ""
	fi
	echo -e "#!/bin/sh\n\nif [ ! -f \"$TARGET\" -a ! -d \"$TARGET\" ];then\n\tndmc -c no system mount $STORAGE:\n\tsleep 15\n\tndmc -c system usb $PORT power shutdown\n\tsleep 15\n\tndmc -c no system usb $PORT power shutdown\n\tsleep 15\n\tndmc -c system mount $STORAGE:\n\tlogger \"USr: выполнено переподключение накопителя.\"\n\tsleep 10\n\techo \"\`date +\"%C%y.%m.%d %H:%M\"\` - выполнено переподключение накопителя.\" >> $LOG\n\techo \"\`date +\"%C%y.%m.%d %H:%M\"\` выполнено переподключение накопителя.\"\nelse\n\tlogger \"USr: накопитель - доступен.\"\n\techo \"\`date +\"%C%y.%m.%d %H:%M\"\` - накопитель - доступен.\"\nfi" > /opt/bin/usr
	chmod +x /opt/bin/usr
	scheduleAdd
	messageBox "Настройка завершена."
	echo ""
	showText "\tТеперь, с периодом в $PERIOD минут(у/ы), скрипт будет проверять доступность файла/папки \"$TARGET\", и в случае отсутствия доступа - выполнит переподключение накопителя: USB $PORT."
	showText "\tОтслеживать работу скрипта - можно в журнале интернет-центра, по событиям с префиксом \"USr:\"..."
	echo ""
	read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	}

function scriptDelete
	{
	echo "Удаление USB-Storage Reconnect..."
	echo ""
	scheduleDelete
	messageBox "Скрипт - удалён."
	echo ""
	rm -rf /opt/bin/usr
	rm -rf $0
	}

function mainMenu
	{
	headLine "USB-Storage Reconnect"
	if [ -f "/opt/bin/usr" ];then
			showText "\tОбнаружен настроенный скрипт."
			echo ""
			echo -e "\t1: Новая конфигурация"
			echo -e "\t2: Удалить скрипт"
			echo -e "\t0: Отмена (по умолчанию)"
			echo ""
			read -r -p "Ваш выбор:"
			echo ""
			if [ "$REPLY" = "1" ];then
				scriptSetup
			elif [ "$REPLY" = "2" ];then
				scriptDelete
			fi
	else
		scriptSetup
	fi
	headLine
	copyRight "USr" "2025"
	clear
	rm -rf $0
	exit
	}

echo;while [ -n "$1" ];do
case "$1" in

-d)	MODE="-d"
	headLine "USB-Storage Reconnect"
	scriptDelete
	exit
	;;

-s)	MODE="-s"
	headLine "USB-Storage Reconnect"
	scriptSetup
	exit
	;;

-v)	echo "$0 $VERSION build $BUILD"
	exit
	;;

*) headLine "pre-Setup"
	messageBox "Введён некорректный ключ." "\033[91m"
	echo ""
	echo "Доступные ключи:"
	showText "\t-d: Удаление скрипта"
	showText "\t-s: Настройка скрипта"
	showText "\t-v: Отображение текущей версии pS"
	echo ""
	exit
	;;
	
esac;shift;done
mainMenu

# Обновление cron/crontabs/root
#echo "`opkg update`" > /dev/null
#echo "`opkg upgrade cron`" > /dev/null

# Переустановка cron/crontabs/root
#opkg remove cron
#opkg install cron

# Перезапуск Cron
#/opt/etc/init.d/S10cron restart
