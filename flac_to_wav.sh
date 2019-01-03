#!/bin/bash
for i in SLR35_Large_Javaneses_asr_training_data;do
       for w in `ls $i/asr_javanese/data/`;do
              #echo $w
               for d in `ls $i/asr_javanese/data/$w`;do
                      name=`basename $d .flac` #读取basename
                      dir_name=`dirname $d` #读取目录
                      [ ! -d /home/twirlinger/workspace2/data/to_wav/$i/asr_javanese/data/$w ] && mkdir -p /home/twirlinger/workspace2/data/to_wav/$i/asr_javanese/data/$w
        		sox /home/twirlinger/workspace2/data/$i/asr_javanese/data/$w/$d -r 16000 -b 16 -c 1 /home/twirlinger/workspace2/data/to_wav/$i/asr_javanese/data/$w/$name.wav
		done
	done
done

