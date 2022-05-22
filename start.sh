#!/bin/bash
if [[ $# -eq 0 ]] ; then
    echo 'You should specify database name!'
    exit 1
fi


export PATH=$PATH:/usr/local/hadoop/bin/
hadoop dfs -rm -r input.1
hadoop dfs -rm -r input.2
# Устанавливаем PostgreSQL
sudo apt-get update -y
sudo apt-get install -y postgresql postgresql-contrib
sudo service postgresql start

# Создаем таблицу
sudo -u postgres psql -c 'ALTER USER postgres PASSWORD '\''1234'\'';'
sudo -u postgres psql -c 'drop database if exists '"$1"';'
sudo -u postgres psql -c 'create database '"$1"';'
sudo -u postgres -H -- psql -d $1 -c 'CREATE TABLE input1 (id BIGSERIAL PRIMARY KEY, time BIGSERIAL ,aeroport1 VARCHAR(20) ,aeroport2 VARCHAR(20));'
sudo -u postgres -H -- psql -d $1 -c 'CREATE TABLE input2 (id BIGSERIAL PRIMARY KEY, aeroport VARCHAR(20) ,country VARCHAR(20));'

# Генерируем входные данные и добавляем их в таблицу
AEROPORT=("AEROPORT1" "AEROPORT2" "AEROPORT3" "AEROPORT4" "AEROPORT5" "AEROPORT6" "AEROPORT7" "AEROPORT8" "AEROPORT9" "AEROPORT10")
COUNTRY=("COUNTRY1" "COUNTRY2")
NUMBER=10
STARTNUMBER=1510670900000

for t in ${AEROPORT[@]};
  do
    COUNTRY_VAR="${COUNTRY[$((RANDOM % ${#COUNTRY[*]}))]}"
    sudo -u postgres -H -- psql -d $1 -c 'INSERT INTO input2 (aeroport, country) VALUES ('\'"$t"\'','\'"$COUNTRY_VAR"\'');'
  done

for i in {1..200}
	do
	    NUMBER=$(($NUMBER + $(($RANDOM % 10000))))
      	    RESULTNUMBER=$(($STARTNUMBER+$NUMBER))
            AEROPORT_VAR1="${AEROPORT[$((RANDOM % ${#AEROPORT[*]}))]}"
            AEROPORT_VAR2="${AEROPORT[$((RANDOM % ${#AEROPORT[*]}))]}"
		sudo -u postgres -H -- psql -d $1 -c 'INSERT INTO input1 (time, aeroport1, aeroport2) VALUES ('\'"$RESULTNUMBER"\'','\'"$AEROPORT_VAR1"\'','\'"$AEROPORT_VAR2"\'');'
	done

# Скачиваем SQOOP
if [ ! -f sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz ]; then
    wget https://archive.apache.org/dist/sqoop/1.4.7/sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz
    tar xvzf sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz
else
    echo "Sqoop already exists, skipping..."
fi

# Скачиваем драйвер PostgreSQL
if [ ! -f postgresql-42.2.5.jar ]; then
    wget --no-check-certificate https://jdbc.postgresql.org/download/postgresql-42.2.5.jar
    cp postgresql-42.2.5.jar sqoop-1.4.7.bin__hadoop-2.6.0/lib/
else
    echo "Postgresql driver already exists, skipping..."
fi

export PATH=$PATH:/sqoop-1.4.7.bin__hadoop-2.6.0/bin

# Скачиваем Spark
if [ ! -f spark-2.3.1-bin-hadoop2.7.tgz ]; then
    wget https://archive.apache.org/dist/spark/spark-2.3.1/spark-2.3.1-bin-hadoop2.7.tgz
    tar xvzf spark-2.3.1-bin-hadoop2.7.tgz
else
    echo "Spark already exists, skipping..."
fi

export SPARK_HOME=/spark-2.3.1-bin-hadoop2.7
export HADOOP_CONF_DIR=$HADOOP_PREFIX/etc/hadoop

sqoop import --connect 'jdbc:postgresql://127.0.0.1:5432/'"$1"'?ssl=false' --username 'postgres' --password '1234' --table 'input1' --target-dir 'input.1'
sqoop import --connect 'jdbc:postgresql://127.0.0.1:5432/'"$1"'?ssl=false' --username 'postgres' --password '1234' --table 'input2' --target-dir 'input.2'

export PATH=$PATH:/spark-2.3.1-bin-hadoop2.7/bin

#spark-submit --class bdtc.lab2.SparkSQLApplication --master local --deploy-mode client --executor-memory 1g --name wordcount --conf "spark.app.id=SparkSQLApplication" /tmp/lab2-1.0-SNAPSHOT-jar-with-dependencies.jar hdfs://127.0.0.1:9000/user/root/input.1/ hdfs://127.0.0.1:9000/user/root/input.2/ out

#echo "DONE! RESULT IS: "
#hadoop fs -cat  hdfs://127.0.0.1:9000/user/root/out/part-00000




