while read line
do
    echo ${line}
    unzip ${line} -d /tmp/bunkei.ziten
    cp /tmp/bunkei.ziten/word/document.xml "/Data/bunkei.ziten/${line}.xml"
    rm -fr /tmp/bunkei.ziten/*
done < "${1:-/dev/stdin}"
