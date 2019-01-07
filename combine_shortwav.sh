#!/bin/bash
#2018.
#usage:
#e.g:
path="/home/twirlinger/workspace2/data/to_wav"
nj=10
out_path="/home/twirlinger/workspace2/data/to_wav/out_combine"


find $path -name "*.wav" >1.txt  #find path/name.wav output txt=list

n=0
while read w; do
	((n++))
	
	{
		dir_n=`dirname $w`  #obtain path
		./combine_wav_dir.sh --nj 20 --time_limit 1800 --tar_dir $out_path  $dir_n #调用combine_wav_dit.sh 并设置参数

	}   
done < 1.txt

##############combine_wav_dir.sh####################
#!/bin/bash
#2018.6.6
#usage: combine wavs into one wav: wav_dir.wav
#e.g:$0 wav_dir

nj=8
time_limit=0  #0:no limit;  >0:combine wav will less than this time(second)
tar_dir=	#output directory
seg_time=	#if every piece of seg wavs have same time duration. set this to the duration time.

#test
if ! . parse_options.sh; then
	echo -e "\033[031mERROR: parse_options.sh not exist\033[0m"  && exit 1 
fi

[ $# -ne 1 ] && echo -e "\033[031mERROR: parameters wrong!\n	$0 [--nj 8 --time_limit 0 --tar_dir . --seg_time 1.5] wav_dir\033[0m"  && exit 1
wav_dir=$1

[ ! -d $1 ] && echo -e "\033[031mERROR: \"$1\" not exist \033[0m"  && exit 1

if [ -z "$tar_dir" ]; then
	tar_dir=./
fi
[ ! -d $tar_dir ] && mkdir -p $tar_dir


#creat list
dir_name=`basename $wav_dir`
echo "create list..."
find $wav_dir -name "*.wav" | sort >tmp.lst
n_wav=`cat tmp.lst | wc -l`
[ $n_wav -eq 0 ] && echo -e "\033[031mERROR: no wav in \"$1\"\033[0m"  && exit 1


if [ -z "$seg_time" ]; then
	echo "create wav-time list..."
	while read l; do
		t=`soxi -D $l`
		echo "$l $t"
	done <tmp.lst | tee $dir_name.lst
else
	sed "s/\.wav/.wav\ $seg_time/g" tmp.lst >$dir_name.lst
fi

[ ! -d .temp ] && mkdir .temp

mkfifo tp
exec 8<>tp
rm tp
for i in `seq $nj`; do
	echo >&8
done


#combine wav(no time limit)
if [ $time_limit -eq 0 ]; then
	n=0
	echo "total $n_wav wavs"
	while [ $n_wav -ne 1 ]; do
		((n++))
		for i in `seq 1 2 $n_wav`; do
			read -u8
			{
			fir_line=$i
			sec_line=$((i+1))
			fir_wav=`sed -n "${fir_line}p" tmp.lst`
			wav_p=`dirname $fir_wav`
			if [ $sec_line -le $n_wav ]; then
				sec_wav=`sed -n "${sec_line}p" tmp.lst`
				sox $fir_wav $sec_wav .temp/tmp${n}_$i.wav
				if [ "$wav_p"x = ".temp"x ]; then
					rm $fir_wav
					rm $sec_wav
				fi
			else
				cp $fir_wav .temp/tmp${n}_$i.wav
				if [ "$wav_p"x = ".temp"x ]; then
					rm $fir_wav
				fi
			fi
			echo >&8
			}&
		done
		wait
		find .temp -name "*.wav" | sort >tmp.lst
		n_wav=`cat tmp.lst | wc -l`
		echo "$n combine to $n_wav wavs"
	done
	echo "done"
	mv .temp/tmp${n}_1.wav $tar_dir/$dir_name.wav
	mv $dir_name.lst $tar_dir/


#combine wav(with time limit)
elif [ $time_limit -gt 0 ]; then
	rm $tar_dir/${dir_name}_combine*.lst &>/dev/null
	echo "creat combine list"
	if [ -z "$seg_time" ]; then	
		n=1
		tt=0

		while read wav t; do
			tt=`echo "$tt+$t"|bc`
			if [ `echo "$tt>=$time_limit"|bc` -eq 1 ]; then
				((n++))
				tt=$t
			fi
			echo "	$n $wav $t"
			echo "$wav $t" >>$tar_dir/${dir_name}_combine$n.lst
		done <$dir_name.lst
	else
		n=0
		numb=`echo "$time_limit/$seg_time"|bc`
		for i in `seq 0 $numb $n_wav`; do
			((n++))
			start_line=$((i+1))
			end_line=$((i+numb))
			echo "	$n ${start_line} ${end_line}"
			[ $end_line -gt $n_wav ] && end_line=$n_wav
			sed -n "${start_line},${end_line}p" $dir_name.lst >$tar_dir/${dir_name}_combine$n.lst
		done
	fi
	#rm $dir_name.lst
	for lst_n in `seq 1 $n`; do
		read -u8
		{
		[ ! -d .temp/$lst_n ] && mkdir -p .temp/$lst_n
		count=0
		echo "combine ${dir_name}_combine${lst_n}.wav"
		n_wav=`cat $tar_dir/${dir_name}_combine${lst_n}.lst | wc -l`
		cat $tar_dir/${dir_name}_combine${lst_n}.lst | awk '{print $1}' >.temp/tmp_${lst_n}.lst
		echo "	${lst_n}:total $n_wav wavs"
		while [ $n_wav -ne 1 ]; do
			[ $n_wav -eq 0 ] && echo "ERROR: no wavs" && exit 1
			((count++))
			for i in `seq 1 2 $n_wav`; do

				fir_line=$i
				sec_line=$((i+1))
				fir_wav=`sed -n "${fir_line}p" .temp/tmp_${lst_n}.lst`
				wav_p=`dirname $fir_wav`
				if [ $sec_line -le $n_wav ]; then
					sec_wav=`sed -n "${sec_line}p" .temp/tmp_${lst_n}.lst`
					sox $fir_wav $sec_wav .temp/$lst_n/tmp${count}_$i.wav
					if [ "$wav_p"x = ".temp/$lst_n"x ]; then
						rm $fir_wav
						rm $sec_wav
					fi
				else
					cp $fir_wav .temp/$lst_n/tmp${count}_$i.wav
					if [ "$wav_p"x = ".temp/$lst_n"x ]; then
						rm $fir_wav
					fi
				fi

			done
			find .temp/$lst_n -name "*.wav" | sort -t_ -n -k2,2 >.temp/tmp_${lst_n}.lst
			n_wav=`cat .temp/tmp_${lst_n}.lst | wc -l`
			echo "	${lst_n}:$count combine to $n_wav wavs"
		done
		mv .temp/$lst_n/tmp${count}_1.wav $tar_dir/${dir_name}_combine${lst_n}.wav
		echo >&8
		}&
	done
else
	echo -e "\033[031mERROR: time_limit >=0 \033[0m"  && exit 1
fi
wait

rm tmp.lst
rm .temp -rf









