#!/bin/bash

#bfs를 돌리기 위한 queue 선언 (배열로써 구현)
#기본적으로 리눅스는 전역변수로써 변수를 다룬다.
declare -a queue

#url을 제공하면 그 사이트를 다운로드 받고 모든 링크 주소를 가져와서
#배열에 저장하는 함수
function get_link_list() {
    #리눅스 쉘스크립트 계열에선 함수 호출시 main a b c 와 같은 식으로 호출하므로
    #$1 , $2 와 같이 인자값을 받아낸다.

    #Shell script에서 선언된 변수는 기본적으로 전역 변수로 되며 지역변수는 함수 내에서 선언할 때에만 사용할 수 있으며
    #변수명 앞에 local를 붙여주면 된다.

    local target_url=$1
    echo "target_url : $target_url"

    #정규식에 따라 모든 a tag의 href(링크) 를 가져오고 array 형태로 저장한다

    #wget :: -O - 옵션. : 파일로 저장하지 않고 모니터 표준 출력(stdout) 으로 꺼내온다.
    #옵션 q = 디버그 로그 출력안함
    #curl 이 우분투 기본 패키지가 아니라 사용할 수 없으므로 이렇게 해야함.. ㅠ

    #echo $(wget -q -O - $target_url)

    link_array=($(wget -q -O - $target_url | grep -Po '(?<=href=")[^"]*'))

    #앞이 http로만 시작하는 절대 경로 https 링크를 가져온다.
    # local i=0
    # for item in "${link_array[@]}"; do
    #     if [ "${item:0:4}" != "http" ]; then
    #         unset "link_array[$i]"
    #         #echo "remove item : $item i : $i"
    #     fi
    #     ((i += 1)) #== i+=1
    # done

    #시작이 http, / 이 아니거나
    #"/" 문자 자체를 걸러낸다.
    local i=0
    for item in "${link_array[@]}"; do
        # echo -e "${item:0:4}\n"
        # echo -e "${item:0:1}\n"
        # echo -e "${item}\n"

        if [ "${item:0:4}" == "http" ] || [ "${item:0:1}" != "/" ] && [ "${item:0:1}" != "h" ] || [ "$item" == "/" ]; then
            unset "link_array[$i]"
            #echo "remove item : $item i : $i"
        fi
        ((i += 1)) #== i+=1
    done

    #작업한 배열 목록 출력 & / 경로 처리

    local j=0
    for item in "${link_array[@]}"; do
        #link is not absolute
        if [ "${item:0:1}" == "/" ]; then
            #item=$target_url${item:1} 이건복사본을 바꾸는듯?
            link_array[j]=$target_url${item:1}
        fi

        ((j += 1))
        #echo -e "$item \n"
    done

}

function bfs() {
    # Add the second array at the end of the first array
    queue=(${queue[@]} ${link_array[@]}) #큐에 요소를 삽입한다.

    echo "url count : ${#queue[@]}"

    local i=0
    while [ ${#queue[@]} -gt 0 ]; do

        #웹 소스 다운로드
        wget -q -P "download" --content-disposition "${queue[$i]}"
        #-P 폴더명 : 원하는 폴더에 다운로드 받기
        #--content-disposition = 헤더로부터 제공되는 파일명으로 다운로드

        get_link_list "${queue[$i]}" #링크 다시 들어가기

        unset "queue[$i]" #queue에서 pop (방문처리)

        queue=(${queue[@]} ${link_array[@]}) #큐에 요소를 삽입한다.
        #echo "${#queue[@]}"

        ((i += 1)) #== i+=1

        sleep 0.3 #안정을 위해 delay
    done

}

#start_idx=0 #탐색 구역용 변수
url="https://www.naver.com/" #처음 탐색을 시작하는 루트 url

get_link_list $url #링크에서 url 목록 담아서 전역 배열 link_array 에 담는다.
bfs                #bfs를 돌린다.

# #file_name="${start_idx}.html"

# #wget -O $file_name $url

# #정규식에 따라 모든 a tag의 href(링크) 를 가져오고 array 형태로 저장한다.
# #link_array=( $(cat $file_name | grep -Po '(?<=href=")[^"]*') )

# #인덱스 증가
# #start_idx+=1

# #폴더를 만든다
# #mkdir $start_idx

# #array 요소를 item이라는 변수에 대입하면서 하나씩 읽어온다. (C++ For ranged Loop와 유사)

# function temp(){
#     for item in "${link_array[@]}"
#     do
#         #시작이 http로 시작하는 것만을 걸러낸다 (https도 포함)
#         #("/" 자체는 root 도메인이므로 재귀 호출의 위험성으로 배제한다.)
#         #참고 /test.html 와 같이
#         if [ "${item:0:4}" = "http" ] && [ "${item:0:1}" != "/" ] && [ "$item" != "/" ]
#         then
#             echo -e "$item\n"
#             wget -P "$start_idx\\" --content-disposition "$item"
#             #-P 폴더명 : 원하는 폴더에 다운로드 받기
#             #--content-disposition = 헤더로부터 제공되는 파일명으로 다운로드
#         fi
#     done
# }
