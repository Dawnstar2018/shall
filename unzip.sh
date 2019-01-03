for i in SLR35_Large_Javaneses_asr_training_data SLR36_Large_Sundanese_asr_training_data SLR38_Free_ST_Chinese_mandarin_corpus SLR47_Primewords_Chinese_Corpus_Set_1 SLR52_Large_Sinhala_asr_training_data SLR53_Large_Bengali_asr_training_data SLR53_Large_Bengali_asr_training_data;do #i在文件夹下循环读取文件夹名字
	      [ ! -d /home/twirlinger/workspace2/data/$i] && mkdir -p /home/twirlinger/workspace2/data/$i  #-d为判断是否有目录，若没有则mkdir 创建文件 -p后为路径
        for w in `ls $i`;do #w循环读取i文件夹下文件
	    	        d=`basename ./$i/$w .zip` #basename读取除目录外的文件名
                unzip -n -d /home/twirlinger/workspace2/data/$i ./$i/$d.zip	#执行解压操作
        done
done
