#!/bin/bash

#bfs를 돌리기 위한 queue 선언 (배열로써 구현)
#기본적으로 리눅스는 전역변수로써 변수를 다룬다.
declare -a queue

#url을 제공하면 그 사이트를 다운로드 받고 모든 링크 주소를 가져와서
#배열에 저장하는 함수
function get_link_list() {
    #리눅스 쉘스크립트 계열에선 함수 호출시 main a b c 와 같은 식으로 호출하므로
    #$1 , $2 와 같이 인자값을 받아낸다.

    #Shell script에서 선언된 변수는 기본적으로 전역 변수로 되며
    #지역변수는 함수 내에서 선언할 때에만 사용할 수 있으며
    #변수명 앞에 local를 붙여주면 된다.

    local target_url=$1
    echo "target_url : $target_url"

    #정규식에 따라 모든 a tag의 href(링크) 를 가져오고 array 형태로 저장한다

    #wget :: -O - 옵션. : 파일로 저장하지 않고 모니터 표준 출력(stdout) 으로 꺼내온다.
    #옵션 q = 디버그 로그 출력안함
    #curl 이 우분투 기본 패키지가 아니라 사용할 수 없으므로 이렇게 해야함.. ㅠ

    #echo $(wget -q -O - $target_url)

    #queue를 담을때 이 전역 배열에서 데이터를 가져올 것이다.
    link_array=() #배열 초기화
    link_array=($(wget -q -O - "$target_url" | grep -Po '(?<=href=")[^"]*')) #a tag의 href url을 정규식으로 전부 파싱하고 배열에 저장한다.

    #url이 발견되지 않으면 0을 return 하고 (정상 종료) 함수를 강제 종료한다.
    if [ ${#link_array[@]} == 0 ]; then
        return
    fi

    #href에는 단순히 https로 시작하는 절대 경로 url만 나오는것이 아니다. 
    #슬래시(/) 를 이용해 상대 경로까지 포함되어 있다
    #아래 코드들은 이를 처리하기 위한 코드들이다.

    #시작이 http, / 이 아니거나
    #"/" 문자 자체를 걸러낸다.
    local i=0
    for item in "${link_array[@]}"; do
        # for debug
        # echo -e "${item:0:4}\n"
        # echo -e "${item:0:1}\n"
        # echo -e "${item}\n"

        if [ "${item:0:4}" == "http" ] || [ "${item:0:1}" != "/" ] && [ "${item:0:1}" != "h" ] || [ "$item" == "/" ]; then
            unset "link_array[$i]"
            #echo "remove item : $item i : $i"
        fi
        ((i += 1)) #== i+=1
    done

    #root url 처리
    #ex) https://web.pgh268400.duckdns.org/page11.html -> https://web.pgh268400.duckdns.org/
    #/ 와 같은 상대경로를 처리하기 위함임.
    if [ "${target_url:(-1)}" != "/" ]; then
        root_url=${target_url%/*}/
        #echo $root_url
    else
        root_url=$target_url
    fi
    #작업한 배열 목록 출력 & / 경로 처리

    #echo "root_url : $root_url"

    local j=0
    for item in "${link_array[@]}"; do
        #link is not absolute
        if [ "${item:0:1}" == "/" ]; then
            #item=$target_url${item:1} 이건복사본을 바꾸는듯?
            link_array[j]=$root_url${item:1} #주소가 /면 들어온 url 과 합쳐서 배열을 바꾼다.
        fi

        ((j += 1))
        #echo -e "$item \n"
    done

    echo "new_url_founded : ${#link_array[@]}"

}

# 모든 처리는 이 함수로 이루어진다.
function bfs() {
    #queue 첫 요소 추가
    get_link_list "$url" #링크에서 url 목록 담아서 전역 배열 link_array 에 담는다.

    if [ ${#link_array[@]} -gt 0 ]; then
        queue=(${queue[@]} ${link_array[@]}) #큐에 요소를 삽입한다. (link_array 에서 꺼내온다.)
    fi

    local i=0
    while [ ${#queue[@]} -gt 0 ]; do
        echo "download queue count : ${#queue[@]}"

        #echo "${queue[@]}"

        #웹 소스 다운로드
        wget -q -P "download" --content-disposition "${queue[0]}"
        #-P 폴더명 : 원하는 폴더에 다운로드 받기
        #--content-disposition = 헤더로부터 제공되는 파일명으로 다운로드

        get_link_list "${queue[0]}" #링크 다시 들어가기
        unset "queue[0]"            #queue에서 pop (방문처리)

        #배열을 unset으로 강제로 지우면 인덱스가 연속적이지 않게 된다.
        #배열 자체 크기가 변경가능한 데이터 구조가 아닌데 리눅스에서 예외적으로 허용되는 것이므로
        #다시 array를 생성해서 배열의 gap을 조정해준다.
        for i in "${!queue[@]}"; do
            new_array+=("${queue[i]}")
        done
        queue=("${new_array[@]}")
        unset new_array

        if [ ${#link_array[@]} -gt 0 ]; then
            queue=(${queue[@]} ${link_array[@]}) #큐에 요소를 삽입한다.
        fi

        #echo "${#queue[@]}"

        ((i += 1)) #== i+=1

        sleep 0.3 #안정을 위해 delay
    done

    echo "queue is clear. download finished"

}

# main function --------------------------------
url="https://web.pgh268400.duckdns.org/" #처음 탐색을 시작하는 루트 url
bfs                                      #bfs를 돌린다.
