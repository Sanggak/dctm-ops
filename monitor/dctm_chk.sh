#! /bin/sh

#### ------------------------------
####  adjust below for each system
#### ------------------------------

ORACLE_HOME=/opt/oracle/product/12.1.0/orcl
ORACLE_SID=orcl
LOGD=/opt/dctm/dba/log
NASD=/opt/dctm/data

case `uname`
in
	Linux)
		SP="\:"
		STAT_CPU=`vmstat 1 2 | tail -1 | awk '{printf "%d,%d,%d,%d", $13, $14, $15, $16}'`
	;;
	AIX)
		SP="\."
		STAT_CPU=`vmstat 1 2 | tail -1 | awk '{printf "%d,%d,%d,%d", $14, $15, $16, $17}'`
	;;
	*)
		SP="\."
		STAT_CPU=`vmstat 1 2 | tail -1 | awk '{printf "%d,%d,%d,%d", $13, $14, $15, $16}'`
	;;
esac

_BRKP="$SP(1489|1490)$"
_DOCP="$SP(49100|49101)$"
_DBP="$SP(1521)$"
CNT_BRKP=`netstat -an | awk '($4 ~ /'"$_BRKP"'/) { print}' |wc -l |sed 's/ //g'`
CNT_DOCP=`netstat -an | awk '($4 ~ /'"$_DOCP"'/) { print}' |wc -l |sed 's/ //g'`
CNT_DBP=` netstat -an | awk '($5 ~ /'"$_DBP"'/ ) { print}' |wc -l |sed 's/ //g'`

TNS="$ORACLE_HOME/bin/tnsping $ORACLE_SID"

CNT_BRK=`ps -eaf | grep dmdocbroker | grep -v grep | wc -l |sed 's/ //g'`
CNT_DOC=`ps -eaf | grep documentum | grep -v grep | wc -l |sed 's/ //g'`

#TZ=KST

#### ------------------------------
####  gathering logs
#### ------------------------------

YYYY=`date +%Y`
MMDD=`date +%m%d`
hh=`date +%H`
mm=`date +%M`

export ORACLE_HOME
export PATH=$PATH:$ORACLE_HOME/bin

HOST=`hostname`
LOGF=$LOGD/dctm_chk_${HOST}_${YYYY}_${MMDD}.csv
TMPF=$NASD/$HOST$$

if [ `touch $TMPF 2>&-` ]; then
	TMPF=`basename $TMPF`

	NAS_WRITE=`(time dd if=$LOGD/10M   of=$NASD/$TMPF bs=1024 count=10240 2>&1) 2>&1 | awk '/real/ {print $2}'|sed -e 's/^/scale=0;1000*(/' -e 's/m/*60+/' -e 's/s$/)\/1/' |bc`
	NAS_READ=` (time dd if=$NASD/$TMPF of=$LOGD/$TMPF bs=1024 count=10240 2>&1) 2>&1 | awk '/real/ {print $2}'|sed -e 's/^/scale=0;1000*(/' -e 's/m/*60+/' -e 's/s$/)\/1/' |bc`
	rm -f $NASD/$TMPF 2>&-
	rm -f $LOGD/$TMPF 2>&-
else 
	NAS_WRITE=0
	NAS_READ=0
fi

if [ ! -f $LOGD/10M ]; then
    dd if=/dev/urandom of=$LOGD/10M bs=1024 count=10240 2>&1 > /dev/null
fi

LOG_FREE_BYTE=`df -k $LOGD 2>&-| tail -1 | awk '{printf "%d\n", $4}'`
LOG_FREE_PERT=`df -k $LOGD 2>&-| tail -1 | awk '{print $5}' | sed 's/%//'`

DB_PING=`$TNS 2>&1 | tail -1`

if [ ! -f $LOGF ]; then
    echo "YYYY,MMDD,hh,mm,LOG_FREE_BYTE,LOG_FREE_PERT,CNT_BRK,CNT_DOC,CNT_BRKP,CNT_DOCP,CNT_DBP,NAS_WRITE,NAS_READ,CPU_us,CPU_sy,CPU_id,CPU_wa,DB_PING" > $LOGF
fi
echo "$YYYY,$MMDD,$hh,$mm,$LOG_FREE_BYTE,$LOG_FREE_PERT,$CNT_BRK,$CNT_DOC,$CNT_BRKP,$CNT_DOCP,$CNT_DBP,$NAS_WRITE,$NAS_READ,$STAT_CPU,$DB_PING" >> $LOGF
