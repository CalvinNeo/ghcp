set -o xtrace

# Update raftstore-proxy-6.1
# PROXY_BRANCH=raftstore-proxy-6.1 TIFLASH=~/tiflash/tiflash TIFLASH_BRANCH=release-6.1 PROXY_REMOTE=git@github.com:pingcap/tidb-engine-ext.git PROXY_PR=0 bash ./update_tiflash_proxy.sh

# Update raftstore-proxy-6.2 to master
# PROXY_BRANCH=raftstore-proxy-6.2 TIFLASH=~/tiflash/tiflash TIFLASH_BRANCH=master PROXY_REMOTE=git@github.com:pingcap/tidb-engine-ext.git PROXY_PR=0 bash ./update_tiflash_proxy.sh

# PROXY_BRANCH=raftstore-proxy-8.1 TIFLASH_BRANCH=release-8.1 TIFLASH=~/tics TIFLASH_BRANCH=master PROXY_REMOTE=git@github.com:calvinneo/tidb-engine-ext.git PROXY_PR=0 bash ./update_tiflash_proxy.sh


# Update raftstore-proxy-6.2 to master to fix issue
# FIXED_ISSUE=123 PROXY_BRANCH=raftstore-proxy-6.2 TIFLASH=~/tiflash/tiflash TIFLASH_BRANCH=master PROXY_REMOTE=git@github.com:pingcap/tidb-engine-ext.git PROXY_PR=0 bash ./update_tiflash_proxy.sh

# Edit Pr of raftstore-proxy-6.2 to master to fix issue
# TIFLASH_PR=5861 FIXED_ISSUE=123 PROXY_BRANCH=raftstore-proxy-6.2 TIFLASH=~/tiflash/tiflash TIFLASH_BRANCH=master PROXY_REMOTE=git@github.com:pingcap/tidb-engine-ext.git PROXY_PR=0 bash ./update_tiflash_proxy.sh

# Update raftstore-proxy to master
# PROXY_BRANCH=raftstore-proxy TIFLASH=~/tics TIFLASH_BRANCH=master PROXY_REMOTE=git@github.com:pingcap/tidb-engine-ext.git PROXY_PR=0 bash ./update_tiflash_proxy.sh

# Edit Pr of raftstore-proxy to master to fix issue
# TIFLASH_PR=6222 PROXY_BRANCH=raftstore-proxy TIFLASH=~/tics TIFLASH_BRANCH=master PROXY_REMOTE=git@github.com:pingcap/tidb-engine-ext.git PROXY_PR=0 bash ./update_tiflash_proxy.sh

# Update 6.5
# PROXY_BRANCH=raftstore-proxy-6.5 TIFLASH=~/tics TIFLASH_BRANCH=release-6.5 PROXY_REMOTE=git@github.com:pingcap/tidb-engine-ext.git PROXY_PR=289 bash ./update_tiflash_proxy.sh

# 7.1 by raftstore-proxy
# PROXY_BRANCH=raftstore-proxy TIFLASH=~/tics TIFLASH_BRANCH=release-7.1 PROXY_REMOTE=git@github.com:pingcap/tidb-engine-ext.git bash ./update_tiflash_proxy.sh

# Update 5.4
# FIXED_ISSUE=6131 PROXY_BRANCH=raftstore-proxy-5.4 TIFLASH=~/tics TIFLASH_BRANCH=release-5.4 PROXY_REMOTE=git@github.com:pingcap/tidb-engine-ext.git PROXY_PR=179 bash ./update_tiflash_proxy.sh

# Update a different branch merge-6.4 to master
# PROXY_BRANCH=merge-6.4 TIFLASH=~/tics TIFLASH_BRANCH=master PROXY_REMOTE=git@github.com:pingcap/tidb-engine-ext.git PROXY_PR=0 bash ./update_tiflash_proxy.sh

# Update to hotfix
# PROXY_BRANCH=raftstore-proxy-5.4 TIFLASH=~/tics TIFLASH_BRANCH=release-5.4-20220531 PROXY_REMOTE=git@github.com:pingcap/tidb-engine-ext.git PROXY_PR=0 bash ./update_tiflash_proxy.sh

# Try a local branch
# PROXY_BRANCH=v2/ps-runtime TIFLASH=~/tics TIFLASH_BRANCH=master PROXY_REMOTE=git@github.com:calvinneo/tidb-engine-ext.git PROXY_PR=0 bash ./update_tiflash_proxy.sh

# Try a local branch of multi rocks master
# PROXY_BRANCH=v2/patch-7.1-for-problems TIFLASH=~/tics TIFLASH_BRANCH=master PROXY_REMOTE=git@github.com:calvinneo/tidb-engine-ext.git PROXY_PR=0 bash ./update_tiflash_proxy.sh

# Try a local branch and modify PR
# TIFLASH_PR=7704 PROXY_BRANCH=use-back-addr-3 TIFLASH=~/tics TIFLASH_BRANCH=master PROXY_REMOTE=git@github.com:calvinneo/tidb-engine-ext.git PROXY_PR=0 bash ./update_tiflash_proxy.sh

# TIFLASH_PR=8022 PROXY_BRANCH=raftstore-proxy TIFLASH=~/tics TIFLASH_BRANCH=master PROXY_REMOTE=git@github.com:pingcap/tidb-engine-ext.git PROXY_PR=0 bash ./update_tiflash_proxy.sh

# PROXY_BRANCH=merge-tikv-near-7.4 TIFLASH=~/tics TIFLASH_BRANCH=master PROXY_REMOTE=git@github.com:calvinneo/tidb-engine-ext.git PROXY_PR=0 bash ./update_tiflash_proxy.sh

# PROXY_BRANCH=upgrade-near-8.2 TIFLASH=~/tics TIFLASH_BRANCH=master PROXY_REMOTE=git@github.com:calvinneo/tidb-engine-ext.git PROXY_PR=0 bash ./update_tiflash_proxy.sh


if [[ -z $PROXY_BRANCH ]]; then
    # raftstore-proxy-x.y
    echo "target proxy branch is not set"
    exit
fi

if [[ -z $TIFLASH ]]; then
    # ~/tiflash/tiflash
    echo "target tiflash dir is not set"
    exit
fi

if [[ -z $TIFLASH_BRANCH ]]; then
    # master
    echo "tiflash branch is not set"
    exit
fi

if [[ -z $PROXY_REMOTE ]]; then
    # git@github.com:pingcap/tidb-engine-ext.git
    echo "proxy remote is not set, should be where the PROXY_BRANCH is"
    exit
fi

if [[ -z $PROXY_PR ]]; then
    echo "proxy pr is not set, you can specify multiple prs splitted by /"
    exit
fi

if [[ -z $TIFLASH_PR ]]; then
    echo "new tiflash pr"
fi

if [[ -z $TIFLASH_REMOTE ]]; then
    export TIFLASH_REMOTE=git@github.com:pingcap/tiflash.git
fi


if [[ -z $TIFLASH_ORIGIN_NAME ]]; then
    echo "default tiflash origin name to origin"
    export TIFLASH_ORIGIN_NAME=origin
fi 

export PR_TEMPLATE=$TIFLASH/.github/pull_request_template.md

export MAC=0
export SEDSPACE=

if [ "$(uname)" == "Darwin" ]; then
	export MAC=1
	export SEDSPACE=''
fi

echo "Update proxy_up/$PROXY_BRANCH"

cd $TIFLASH
git remote add upstream git@github.com:pingcap/tiflash.git
git fetch upstream $TIFLASH_BRANCH

if [[ -z $TIFLASH_PR ]]; then
    export B=update_proxy_$TIFLASH_BRANCH_$PROXY_PR_`date +%Y%m%d_%H%M%S`
    git checkout -b $B upstream/$TIFLASH_BRANCH
else
    # re-use current branch
    export B=`git rev-parse --abbrev-ref HEAD`
fi

echo "Branch is", $B

pushd contrib/tiflash-proxy
git remote remove proxy_up
git remote add proxy_up $PROXY_REMOTE
git fetch proxy_up $PROXY_BRANCH
git checkout proxy_up/$PROXY_BRANCH
popd
git add contrib/tiflash-proxy
if [ $PROXY_PR -eq 0 ]; then
    git commit -s -m"update tiflash proxy to proxy_up/$PROXY_BRANCH"
else
    git commit -s -m"update tiflash proxy to proxy_up/$PROXY_BRANCH for proxy pr $PROXY_PR"
fi
git push $TIFLASH_ORIGIN_NAME $B

export NEW_TEMPLATE=/tmp/pull_request_template$B.md


cp $PR_TEMPLATE $NEW_TEMPLATE
# Set up issue
if [[ -z $FIXED_ISSUE ]]; then
    sed -i SEDSPACE 's/close #xxx/ref #4982/g' $NEW_TEMPLATE
else
    sed -i SEDSPACE "s/close #xxx/close #$FIXED_ISSUE ref #4982/g" $NEW_TEMPLATE
fi
# Set up desc
export SUBMODULE_DIFF=`git diff upstream/$TIFLASH_BRANCH..HEAD --submodule=log -- contrib/tiflash-proxy`
export PROB_DESC="Including:\n$SUBMODULE_DIFF"
export ESCAPED_PROB_DESC=$(printf '%s\n' "$PROB_DESC" | sed -e 's/[]\/$*.^[]/\\&/g')
export ESCAPED_PROB_DESC=${ESCAPED_PROB_DESC//$'\n'/\\n}


if [ $PROXY_PR -ne 0 ]; then
    while IFS='/' read -ra S; do
      for i in "${S[@]}"; do
        U=https://github.com/pingcap/tidb-engine-ext/pull/$i
        U=$(printf '%s\n' "$U" | sed -e 's/[]\/$*.^[]/\\&/g')
        PROXY_PR_URL="$PROXY_PR_URL\n$U"
      done
    done <<< "$PROXY_PR"
fi

sed -i SEDSPACE "s/Summary:/Summary:\n update proxy to $PROXY_BRANCH\n Proxy PR: $PROXY_PR_URL\n $ESCAPED_PROB_DESC/g" $NEW_TEMPLATE


if [ $PROXY_PR -ne 0 ]; then
    export TITLE="update proxy of $TIFLASH_BRANCH to $PROXY_BRANCH by proxy pr $PROXY_PR" 
else
    export TITLE="update proxy of $TIFLASH_BRANCH to $PROXY_BRANCH"
fi

if [[ -z $TIFLASH_PR ]]; then
    gh pr create --title "$TITLE" -F $NEW_TEMPLATE --base $TIFLASH_BRANCH -R $TIFLASH_REMOTE
    echo "EDIT THIS PR WITH:"
    echo "TIFLASH_PR=TODO" "$@"
else
    gh pr edit $TIFLASH_PR --title "$TITLE" -F $NEW_TEMPLATE --base $TIFLASH_BRANCH -R $TIFLASH_REMOTE
fi