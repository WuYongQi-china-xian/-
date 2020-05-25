#!/bin/bash

git=$(which git)
src_branch=$1
src_warehouse=$2
code_workspace=tmp_code
tar_branch=$3
tar_warehouse=$4
init_dir=$(pwd)
user_commit=${5:-""}

function downloadsrccode(){
    $git clone -b ${src_branch} ${src_warehouse};ret=$?
    if [[ $ret -ne 0 ]];then
        echo "download ${src_warehouse} ${src_branch} code was failed"
    fi
}

function downloadetarcode(){
    $git clone -b ${tar_branch} ${tar_warehouse}
    if [[ $ret -ne 0 ]];then
        echo "download ${tar_warehouse} ${tar_branch} code was failed"
    fi
}

function pushsrctotargetcode(){
    $git status
    $git add -A *
    $git commit -a -m "from qci mr ${user_commit}"
    $git push origin ${tar_branch} 
    if [[ $ret -ne 0 ]];then
        echo "qci push ${src_warehouse} ${src_branch} to ${tar_warehouse} ${tar_branch} code was failed"
    fi
}

function setgit(){
    echo ${tar_warehouse} > ~/.git-credentials
    local issetstore=$(cat ~/.gitconfig | grep "[credential]" -A 40 | grep "helper = store")
    if [[ -z ${issetstore} ]];then
        $git config --global credential.helper store
        echo "set git credential"
    else
        echo "no need set git credential"
    fi
}

function cleangit(){
    $git config --global --remove-section credential
    rm -f ~/.git-credentials
    echo "clean git credential"
}

main(){
    if [[ -d ${code_workspace} ]];then
        rm -rf ${code_workspace}
    fi
    mkdir -p ${code_workspace}/src
    mkdir -p ${code_workspace}/tar
    cd ${code_workspace}/tar
    downloadetarcode
    tar_doc=$(ls) 
    cd ${init_dir}/${code_workspace}/src
    downloadsrccode
    src_doc=$(ls)
    if [[ -z ${user_commit} ]];then	
        cd ${src_doc}
        last_commit=$(git log -1 | awk 'END{print $0}')
        last_commit_date=$(git log -1 | awk 'NR==3{print $0}')
        user_commit="${last_commit} ${last_commit_date}"
		cd ..
	fi
    echo ${user_commit}
    rm -rf ${init_dir}/${code_workspace}/tar/${tar_doc}/*
    cp -rf ${init_dir}/${code_workspace}/src/${src_doc}/* ${init_dir}/${code_workspace}/tar/${tar_doc}/
    setgit
    cd ${init_dir}/${code_workspace}/tar/${tar_doc}
    pushsrctotargetcode
    cleangit
    cd ${init_dir}
}
main

使用方法sh asynccode.sh master http://用户名:密码@git.xxx.com/xxx/xxx.git master https://用户名:私有token@github.com/xxx/xxx.git

# -*- coding: UTF-8 -*-
import sys
import subprocess
import argparse

if sys.getdefaultencoding()!='utf-8':
    reload(sys)
    sys.setdefaultencoding('utf-8')
    
class PULL_PUSCH_CODE(object):

    def __init__(self):
        pass
        
    def start_pull_and_push_code(self,args):
        src_branch=args.src_branch
        if src_branch == "" or src_branch is None:
            print('源仓库指定分支不能为空')
            sys.exit(1)
        src_warehouse=args.src_warehouse
        if src_warehouse == "" or src_warehouse is None:
            print('源仓库地址不能为空')
            sys.exit(1)
        elif not (src_warehouse.startswith("https://") or src_warehouse.startswith("http://")):
            print('源仓库请输入git得url地址，以http://或https://开头')
            sys.exit(2)
        elif src_warehouse.count("//") != 1:
            print('源仓库git url 里有多余得//')
            sys.exit(3)
        tar_branch=args.tar_branch
        if tar_branch == "" or tar_branch is None:
            print('目标仓库指定分支不能为空')
            sys.exit(1)
        tar_warehouse=args.tar_warehouse
        if tar_warehouse == "" or tar_warehouse is None:
            print('目标仓库地址不能为空')
            sys.exit(1)
        elif not (tar_warehouse.startswith("https://") or tar_warehouse.startswith("http://")):
            print('目标仓库请输入git得url地址，以http://或https://开头')
            sys.exit(2)
        elif tar_warehouse.count("//") != 1:
            print('目标仓库git url 里有多余得//')
        user_commit=args.user_commit
        if user_commit is None:
            print('如果版本提交评论是空对象，转为空字符串')
            user_commit=''
        src_user=args.src_user
        if src_user is None:
            print('如果源用户名是空对象，转为空字符串')
            src_user=''
        src_pass=args.src_pass
        if src_pass is None:
            print('如果源用户密码是空对象，转为空字符串')
            src_pass=''
        tar_user=args.tar_user
        if tar_user is None:
            print('如果目标用户名是空对象，转为空字符串')
            tar_user=''
        tar_pass=args.tar_pass
        if tar_pass is None:
            print('如果目标用户密码是空对象，转为空字符串')
            tar_user=''
        try:
            src_warehouse_split=src_warehouse.split('//')
            src_final_warehouse=src_warehouse_split[0]+'//'+src_user+':'+src_pass+'@'+src_warehouse_split[1]
            tar_warehouse_split=tar_warehouse.split('//')
            tar_final_warehouse=tar_warehouse_split[0]+'//'+tar_user+':'+tar_pass+'@'+tar_warehouse_split[1]
            cmd='sh '+sys.path[0]+'/asynccode.sh '+src_branch+' '+src_final_warehouse+' '+tar_branch+' '+tar_final_warehouse+' '+user_commit
            print("cmd:{0}".format(cmd))
            #out_bytes = subprocess.check_output([cmd,src_branch,src_final_warehouse,tar_branch,tar_final_warehouse,user_commit])
            out_bytes = subprocess.check_output(cmd,shell=True)
        except subprocess.CalledProcessError as e:
            out_bytes = e.output       # Output generated before error
            code = e.returncode   # Return code    
        
        

if __name__ == '__main__':
    # 获取参数
    main_parser = argparse.ArgumentParser(description='qci pull code push code script')

    subparsers = main_parser.add_subparsers(
        dest='parser', title='list of command', metavar='COMMAND')
    subparsers.required = True
    pull_push_code = PULL_PUSCH_CODE()

    sub_parser0 = subparsers.add_parser(
        "start_pull_and_push_code", help="clone src git url to add commit and push target git url")
    sub_parser0.add_argument('--src_branch', '-src_branch',
                             type=str, help='src branch name', required=True)
    sub_parser0.add_argument('--src_warehouse', '-src_warehouse',
                             type=str, help='src git http or https url', required=True)     
    sub_parser0.add_argument('--tar_branch', '-tar_branch',
                             type=str, help='target branh name', required=True)
    sub_parser0.add_argument('--tar_warehouse', '-tar_warehouse',
                             type=str, help='target git http or https url', required=True)   
    sub_parser0.add_argument('--user_commit', '-user_commit',
                             type=str, help='if it was blank,user_commit was src git last log,else you write commit was used', required=True)
    sub_parser0.add_argument('--src_user', '-src_user',
                             type=str, help='src git user name', required=True)
    sub_parser0.add_argument('--src_pass', '-src_pass',
                             type=str, help='src git password', required=True)  
    sub_parser0.add_argument('--tar_user', '-tar_user',
                             type=str, help='target git user name', required=True)
    sub_parser0.add_argument('--tar_pass', '-tar_pass',
                             type=str, help='target git password', required=True)                             
    sub_parser0.set_defaults(func=pull_push_code.start_pull_and_push_code)
    args = main_parser.parse_args()
    args.func(args)

使用方法
python3 src/run.py start_pull_and_push_code -src_branch master -src_warehouse http://git.xxx.com/xxx/xxx.git -tar_branch master -tar_warehouse https://github.com/xxx/xxx.git -user_commit '' -src_user xxx -src_pass xxx -tar_user xxx -tar_pass xxx
