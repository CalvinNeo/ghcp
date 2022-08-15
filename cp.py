#coding: utf8

import subprocess
import os, sys
import pycurl
from io import StringIO, BytesIO
from urllib.parse import urlencode
import json
import argparse
import shutil

CP_VERSIONS = ["5.0", "5.1", "5.2", "5.3", "5.4"]

PROXY = '/Users/calvin/tidb-engine-ext'
TIFLASH = '/Users/calvin/tiflash/tiflash'
PROXY_REMOTE = 'git@github.com:pingcap/tidb-engine-ext.git'

def check_pr_status():
    '''
    Whether pr is of this release, and whether it is merged.
    '''

class OriginPR():
    def __init__(self):
        pass

def resolve_origin_pr(origin_pr):
    # request
    token = "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"
    q = '''
    query {
      repository(owner: "tikv", name: "tikv") {
        pullRequest(number: ''' + str(origin_pr) + ''') {
                    merged
          mergeCommit {
            commitUrl
            oid
          }
        }
      }
    }
    '''

    response = BytesIO()
    c = pycurl.Curl()
    c.setopt(c.WRITEFUNCTION, response.write)
    c.setopt(c.URL, 'https://api.github.com/graphql')
    c.setopt(c.HTTPHEADER, ['Authorization: bearer {}'.format(token)])
    j = json.dumps({"query": q})
    # print(j)
    c.setopt(c.POSTFIELDS, j)
    c.perform()
    c.close()
    resp = response.getvalue()
    response.close()

    # parse
    j = json.loads(resp)

    x = j["data"]["repository"]["pullRequest"]

    assert 'merged' in x and bool(x['merged'])
    assert 'mergeCommit' in x
    assert 'oid' in x['mergeCommit']
    assert 'commitUrl' in x['mergeCommit']

    p = OriginPR()
    p.commit = x['mergeCommit']["oid"]
    p.commitUrl = x['mergeCommit']['commitUrl']
    p.merged = bool(x['merged'])
    return p


class CherryPickPR():
    def __init__(self):
        pass

def resolve_cp_prs(origin_pr):
    # request
    token = "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"
    q = '''
    query { 
      repository(owner: "tikv", name: "tikv") {
        pullRequest(number: ''' + str(origin_pr) + ''') {
          timelineItems(first: 10, itemTypes: [CROSS_REFERENCED_EVENT]) {
            nodes {
              ... on CrossReferencedEvent {
                source {
                  __typename
                  ... on PullRequest {
                    baseRefName
                    number
                    merged
                    mergeCommit {
                      commitUrl
                      oid
                    }
                    labels(first:100) {
                      edges {
                        node {
                          name
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
    '''
    response = BytesIO()
    c = pycurl.Curl()
    c.setopt(c.WRITEFUNCTION, response.write)
    c.setopt(c.URL, 'https://api.github.com/graphql')
    c.setopt(c.HTTPHEADER, ['Authorization: bearer {}'.format(token)])
    j = json.dumps({"query": q})
    # print(j)
    c.setopt(c.POSTFIELDS, j)
    c.perform()
    c.close()
    resp = response.getvalue()
    response.close()

    # parse
    j = json.loads(resp)


    PRs = {}
    for x in j["data"]["repository"]["pullRequest"]["timelineItems"]["nodes"]:
        p = CherryPickPR()
        x = x["source"]
        if 'number' in x.keys():
            p.pr = int(x['number'])
        else:
            continue
        if 'merged' in x.keys():
            p.merged = bool(x['merged'])
        else:
            continue
        if 'mergeCommit' in x.keys():
            if x['mergeCommit'] is not None and 'oid' in x['mergeCommit'] and 'commitUrl' in x['mergeCommit']:
                p.commit = x['mergeCommit']["oid"]
                p.commitUrl = x['mergeCommit']['commitUrl']
        else:
            continue
        if 'baseRefName' in x.keys():
            # which tikv release branch is this pr to
            p.release = x['baseRefName']
        else:
            continue
        if 'labels' in x.keys():
            flag = False
            for xx in x['labels']['edges']:
                if xx['node']['name'] == "type/cherry-pick":
                    flag = True
                    break
            if not flag:
                print("DEBG> PR {} is not a cherry-pick".format(p.pr))
                continue
        else:
            continue

        PRs[p.release] = p

    return PRs

VMAP = {
    # Proxy -> TiKV
    "5.0": "5.0",
    "5.1": "5.1",
    "5.2": "5.2",
    "5.3": "5.1",
    "5.4": "5.1",
    "6.0": "5.1",
    "6.1": "6.0",
    "6.2": "6.1",
}


def handle_by_version(origin_pr, cp_versions):
    '''
    for version in cp_versions:
        cherry pick tikv:release-vmap[version] to proxy:release-version
    '''
    resolve_cp_prs(11782)
    proxy_branches = map(lambda x: "raftstore-proxy-" + x, cp_versions)
    tikv_branches = map(lambda x: "release-" + VMAP[x], cp_versions)

    for (cpv, tikv_branch, proxy_branch) in zip(cp_versions, tikv_branches, proxy_branches):
        pass

def get_origin_args_str():
    origin_arg_txt = ""
    if len(sys.argv) > 1:
        for a in sys.argv[1:]:
            if not a.startswith("--version") and not a.startswith("--fixed") and not a.startswith("--proposed_proxy"):
                origin_arg_txt += a
                origin_arg_txt += " "
    return origin_arg_txt

def compose_back_file(origin_pr, fixed_version, rest_version_list):
    pwd = os.path.dirname(os.path.realpath(sys.argv[0]))
    exe = pwd + "/" + sys.argv[0]

    # TODO maybe we can simply remove fixed_version from version
    origin_arg_txt = get_origin_args_str()
    print("DEBG> Compose back.sh with", origin_arg_txt)
    rest_version_str = "--version " + ":".join(rest_version_list) if len(rest_version_list) else ""
    with open("{}/back.sh".format(PROXY), "w") as f:
        content = '''
        export PR={}
        export BACKDIR={}
        export BACKEXE={}
        export FIXEDVERSION={}

        git status

        cd $BACKDIR
        python3 $BACKEXE {} --fixed $FIXEDVERSION {}
        '''.format(origin_pr, pwd, exe, fixed_version, origin_arg_txt, rest_version_str)
        f.write(content)

    shutil.copy("{}/back.sh".format(PROXY), "back.sh")

    with open("{}/abort.sh".format(PROXY), "w") as f:
        content = '''
        cd {}
        '''.format(pwd)
        f.write(content)


def resolve_release_pr(origin_pr, version):
    all_prs = resolve_cp_prs(origin_pr)
    need_tikv_pr = "release-" + VMAP[version]
    return all_prs[need_tikv_pr]

def handle_by_master(origin_pr, cp_versions, fixed_version, proposed_proxy, cherry_pick_by_release):
    # use the original commit
    # TODO if we need to cherry pick from other branch, we need to change this
    origin_p = resolve_origin_pr(origin_pr)
    if cherry_pick_by_release:
        print("INFO> The original commit on master is {}, we do not use that".format(origin_p.commitUrl))
    else:
        print("INFO> The original commit on master is {}, we just use that".format(origin_p.commitUrl))

    def pr_or_push_proxy(origin_pr, p, version, rest_version_list):
        local_branch = get_proxy_branch(origin_pr, version)
        returncode = subprocess.call(['git', 'push', 'origin', local_branch], cwd=PROXY)
        if returncode != 0:
            print("ERROR> Push local fail")
            sys.exit(1)
        body = json.dumps({
            # The commit we actually use
            "commit": p.commit,
            "url": p.commitUrl,
            # The commit in master
            "originCommit": origin_p.commit,
            "originUrl": origin_p.commitUrl,
            "pr_id": origin_pr,
        })
        # pr_url must be valid
        (pr_url, pr_id) = create_proxy_pr(origin_pr, version, body)
        pwd = os.path.dirname(os.path.realpath(sys.argv[0]))
        exe = pwd + "/" + sys.argv[0]
        origin_arg_txt = get_origin_args_str()
        rest_version_str = "--version " + ":".join(rest_version_list) if len(rest_version_list) else ""
        print("DEBG> Compose next.sh with", origin_arg_txt)
        with open("{}/next.sh".format(PROXY), "w") as f:
            content = '''
            export PR={}
            export BACKDIR={}
            export BACKEXE={}
            export PROXY_PR={}

            git status

            cd $BACKDIR
            python3 $BACKEXE {} {} --proposed_url $PROXY_PR
            '''.format(origin_pr, pwd, exe, pr_id, origin_arg_txt, rest_version_str)
            f.write(content)
        print("INFO> Please merge {}, then sh next.sh".format(pr_url))
        sys.exit(0)

    def resolve_p(v):
        p = origin_p
        if cherry_pick_by_release:
            p = resolve_release_pr(origin_pr, v)
            if not p.merged:
                print("ERROR> This PR for release {} is not even merged on TiKV".format(v))
                return None
        return p

    if fixed_version is not None:
        print("INFO> You have just resolved conflict at {}, we will create a proxy pr.".format(fixed_version))
        file_path = "{}/back.sh".format(PROXY)
        if os.path.isfile(file_path):
            os.remove(file_path)
        if os.path.isfile("back.sh"):
            os.remove("back.sh")
        p = resolve_p(fixed_version)
        assert p is not None
        pr_or_push_proxy(origin_pr, p, fixed_version, cp_versions)
        # Should exit
    elif proposed_proxy is not None:
        # Proxy PR is merged
        print("INFO> You have just merged Proxy PR {}, we update to TiFlash".format(fixed_version))
        # TODO check if it is actually merged.
        update_tiflash(origin_pr, cp_versions, proposed_proxy)
        # After create TiFlash PR, we can still resume

    for v in cp_versions:
        assert fixed_version is None

        p = resolve_p(v)
        if p is None:
            continue
        tikv_commit = p.commit
        proxy_branch = "raftstore-proxy-" + v
        local_branch = get_proxy_branch(origin_pr, v)
        e = dict(os.environ)
        e['PROXY'] = PROXY
        e['TIKVCOMMIT'] = tikv_commit
        e['PROXYBRANCH'] = proxy_branch
        e['BRANCH'] = local_branch
        print("INFO> start processing version {}, TiKV commit {}, Proxy branch {}, Local branch {}".format(v, tikv_commit, proxy_branch, local_branch))
        returncode = subprocess.call(['bash', './cp.sh'], env=e)
        if returncode == 1:
            compose_back_file(origin_pr, v, [x for x in cp_versions if x != v])
            print("WARN> Resolve conflicts, call git add and git commit, then call source ./back.sh\ncd {}".format(PROXY))
            sys.exit(0)
        else:
            print("INFO> Prepare PR to Proxy")
            pr_or_push_proxy(origin_pr, p, v, [x for x in cp_versions if x != v])
            # Show exit

def get_proxy_branch(origin_pr, version):
    return "pr{}_ver{}".format(origin_pr, version)

def create_proxy_pr(origin_pr, version, body):
    # request
    token = "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"
    branch = "raftstore-proxy-" + version
    title = "[CHERRYPICK TIKV]: PR {} TO RELEASE {}".format(origin_pr, version)
    head = "CalvinNeo:{}".format(get_proxy_branch(origin_pr, version))
    response = BytesIO()
    c = pycurl.Curl()
    c.setopt(c.WRITEFUNCTION, response.write)
    c.setopt(c.URL, 'https://api.github.com/repos/pingcap/tidb-engine-ext/pulls')
    c.setopt(c.HTTPHEADER, ['Authorization: token {}'.format(token), "Accept: application/vnd.github+json"])
    j = json.dumps({"title": title, "body": body, "head": head, "base": branch})
    print(j)
    c.setopt(c.POSTFIELDS, j)
    c.perform()
    c.close()
    resp = response.getvalue()
    response.close()
    
    # parse
    j = json.loads(resp)
    if not 'url' in j or not 'number' in j:
        print("ERROR> GitHub returns {}", resp)
        sys.exit(1)
    return (j['url'], j['number'])

def update_tiflash(origin_pr, version, proxy_pr):
    # create a tiflash pr to update proxy
    
    e = dict(os.environ)
    e['TIFLASH'] = PROXY
    e['TIFLASH_BRANCH'] = "release-" + version
    e['PROXY_REMOTE'] = PROXT_REMOTE
    e['PROXY_PR'] = proxy_pr
    e['PROXY_BRANCH'] = "raftstore-proxy-" + version
    print("INFO> start update tiflash {} {} {} {} {}".format(v, tikv_commit, proxy_branch, local_branch))
    returncode = subprocess.call(['bash', './cp.sh'], env=e)
    returncode = subprocess.call(['bash', './cp.sh'], env=e)
    if returncode == 1:
        compose_back_file(origin_pr, v, [x for x in cp_versions if x != v])
        print("WARN> Resolve conflicts, call git add and git commit, then call source ./back.sh\ncd {}".format(PROXY))
        sys.exit(0)
    else:
        print("INFO> Prepare PR to Proxy")
        pr_or_push_proxy(origin_pr, v, [x for x in cp_versions if x != v])
        # Show exit

def main():
    parser = argparse.ArgumentParser(description='Process some integers.')
    parser.add_argument('--pr', metavar='p', type=int, help='pr to pick')
    parser.add_argument('--version', metavar='v', type=str, help='proxy versions to fix')
    parser.add_argument('--fixed', type=str, help='resume at fixed_version')
    parser.add_argument('--proposed_proxy', type=int, help='resume at pull request for proxy')

    args = parser.parse_args()
    # handle(11782, ["5.0", "5.1", "5.2", "5.3", "5.4"])
    # handle_by_master(11782, ["5.0", "5.1", "5.2", "5.3", "5.4"])

    e = dict(os.environ)
    e['PROXY'] = PROXY
    subprocess.Popen(['bash', './setup.sh'], env=e)
    assert(args.pr is not None)
    assert(not (args.version is None and args.fixed is None and args.proposed_proxy is None))
    cp_versions = [] if args.version is None else args.version.split(":")
    handle_by_master(args.pr, cp_versions, args.fixed, args.proposed_proxy, True)

if __name__ == '__main__':
    main()

