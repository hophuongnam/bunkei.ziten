#!/bin/bash

while true
do
    cd "/Data/bunkei.ziten/OneDrive - my.smccd.edu"
    inotifywait -e move_self bunkei*docx
    sleep 5
    # pushd .

    ls bunkei*docx | ./docx2xml.sh
    sleep 5

    cd /Data/bunkei.ziten
    ruby bunkei.ziten.rb

    # rm *docx.xml
    sleep 5

    git add --all
    git commit -m "$(date)"
    git push -u origin master

    sleep 5

    # cp ../time4vps.html/* ../hophuongnam.github.io/

    # rsync -av --delete --exclude=.* ../time4vps.html/ ../hophuongnam.github.io/
    cd /Data/hophuongnam.github.io
    git add --all
    git commit -m "$(date)"
    git push -u origin master

    # popd
done
