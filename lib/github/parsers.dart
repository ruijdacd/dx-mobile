// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file. (https://github.com/efortuna/dwmpr/blob/master/LICENSE)

/// Set of hand-crafted JSON parsers for GraphQL responses

import 'dart:convert';
import 'pullrequest.dart';
import 'issue.dart';
import 'repository.dart';
import 'timeline.dart';
import 'user.dart';
import 'label.dart';

/// Parses a Github GraphQL user response
User parseUser(String resBody) {
  final jsonRes = json.decode(resBody)['data'];
  final userJson = jsonRes['viewer'] ?? jsonRes['user'];
  return User(userJson['login'], userJson['name'], userJson['avatarUrl']);
}

/// Parses a Github GraphQL pull request reviews response
/// NOT USED
// List<PullRequest> parseOpenPullRequestReviews(String resBody) {
//   List jsonRes = json.decode(resBody)['data']['search']['edges'];
//   return jsonRes.map((edge) {
//     final node = edge['node'];
//     final orgName = node['organization']['login'];
//     final repoName = node['repository']['name'];
//     final repoUrl = node['repository']['url'];
//     final repoStarCount = node['repository']['stargazers']['totalCount'];
//     final repo = Repository(repoName, repoUrl, orgName, repoStarCount);

//     final prId = node['id'];
//     final prTitle = node['title'];
//     final prUrl = node['url'];
//     final pr = PullRequest(prId, prTitle, prUrl, repo, '', 0);

//     return pr;
//   }).toList();
// }

// -------------------------------------------------------------------------------------
// NON CHROMIUM AUTHOR CODE BELOW (the code below is under MIT license)

// parseBranches parses the result from the GraphQL query for fetching the # of branches
int parseBranches(String resBody) {
  int jsonRes =
      json.decode(resBody)['data']['repository']['refs']['totalCount'];
  return jsonRes;
}

// parseReleases parses the result from the GraphQL query for fetching the # of releases
int parseReleases(String resBody) {
  int jsonRes =
      json.decode(resBody)['data']['repository']['refs']['totalCount'];
  return jsonRes;
}

// parsePullRequests parses the result from the GraphQL query for fetching the PRs for a repo
List<PullRequest> parsePullRequests(String resBody, String owner, String repoName) {
  List jsonRes =
    json.decode(resBody)['data']['search']['edges'];

  Repository repo = Repository(repoName, owner + "/" + repoName);

  List<PullRequest> prs = [];
  for (var i = 0; i < jsonRes.length; i++) {
    try {
      List<Label> labels = [];
      if (jsonRes[i]['node']['labels']['nodes'].length != 0){
        for (var j = 0; j < jsonRes[i]['node']['labels']['nodes'].length; j++){
          labels.add(Label(jsonRes[i]['node']['labels']['nodes'][j]['name'], jsonRes[i]['node']['labels']['nodes'][j]['color']));
        }
      }

      prs.add(PullRequest(
        jsonRes[i]['node']['id'],
        jsonRes[i]['node']['title'],
        jsonRes[i]['node']['url'],
        repo,
        jsonRes[i]['node']['author']['login'],
        jsonRes[i]['node']['number'],
        labels
      ));

    } catch(e) {
      if (e == NoSuchMethodError) {
        List<Label> labels = [];
        if (jsonRes[i]['node']['labels']['nodes'].length != 0){
          for (var j = 0; j < jsonRes[i]['node']['labels']['nodes'].length; j++){
            labels.add(Label(jsonRes[i]['node']['labels']['nodes'][j]['name'], jsonRes[i]['node']['labels']['nodes'][j]['color']));
          }
        }

        prs.add(PullRequest(
          jsonRes[i]['node']['id'],
          jsonRes[i]['node']['title'],
          jsonRes[i]['node']['url'],
          repo,
          "ghost",
          jsonRes[i]['node']['number'],
          labels
        ));
      }
    }

  }
  return prs;
}

// parseIssues parses the result from the GraphQL query for fetching the issues for a repo
List<Issue> parseIssues(String resBody, String owner, String repoName) {
  List jsonRes = json.decode(resBody)['data']['search']['edges'];
  Repository repo = Repository(repoName, owner + "/" + repoName);

  List<Issue> issues = [];
  for (var i = 0; i < jsonRes.length; i++) {
    try {
      List<Label> labels = [];
      if (jsonRes[i]['node']['labels']['nodes'].length != 0){
        for (var j = 0; j < jsonRes[i]['node']['labels']['nodes'].length; j++){
          labels.add(Label(jsonRes[i]['node']['labels']['nodes'][j]['name'], jsonRes[i]['node']['labels']['nodes'][j]['color']));
        }
      }

      issues.add(Issue(
        jsonRes[i]['node']['title'],
        jsonRes[i]['node']['id'],
        jsonRes[i]['node']['url'],
        repo,
        jsonRes[i]['node']['author']['login'],
        jsonRes[i]['node']['state'],
        jsonRes[i]['node']['number'],
        labels
      ));
    } catch(e) {
      if (e == NoSuchMethodError){
        List<Label> labels = [];
        if (jsonRes[i]['node']['labels']['nodes'].length != 0){
          for (var j = 0; j < jsonRes[i]['node']['labels']['nodes'].length; j++){
            labels.add(Label(jsonRes[i]['node']['labels']['nodes'][j]['name'], jsonRes[i]['node']['labels']['nodes'][j]['color']));
          }
        }

        issues.add(Issue(
          jsonRes[i]['node']['title'],
          jsonRes[i]['node']['id'],
          jsonRes[i]['node']['url'],
          repo,
          "ghost",
          jsonRes[i]['node']['state'],
          jsonRes[i]['node']['number'],
          labels
        ));
      }
    }
  }
  return issues;
}

// parsePRTimeline parses the result from the GraphQL query for fetching the timeline for a PR
List<TimelineItem> parsePRTimeline(String resBody, PullRequest pr) {
  List jsonRes = json.decode(resBody)['data']['repository']['pullRequest']
      ['timeline']['edges'];

  List<TimelineItem> prTimeline = [];
  for (var i = 0; i < jsonRes.length; i++) {
    Map temp = jsonRes[i]['node'];
    if (temp.keys.contains('bodyText')) {
      prTimeline.add(IssueComment(pr, null, temp['id'], temp['url'], "",
          temp['author']['login'], temp['bodyText']));
    } else if (temp.keys.contains('message')) {
      if (temp['author']['user'] == null) {
        prTimeline.add(Commit(
          pr,
          null,
          temp['id'],
          temp['url'],
          "",
          "",
          temp['message'],
        ));
      } else {
        prTimeline.add(Commit(
          pr,
          null,
          temp['id'],
          temp['url'],
          "",
          temp['author']['user']['login'],
          temp['message'],
        ));
      }
    } else if (temp.keys.contains('label')) {
      prTimeline.add(LabeledEvent(pr, null, temp['id'], temp['label']['url'],
          "", temp['actor']['login'], temp['label']['name']));
    }
  }
  return prTimeline;
}

// parseIssueTimeline parses the result from the GraphQL query for fetching the timeline for an issue
List<TimelineItem> parseIssueTimeline(String resBody, Issue issue) {
  List jsonRes =
      json.decode(resBody)['data']['repository']['issue']['timeline']['edges'];

  List<TimelineItem> issueTimeline = [];
  for (var i = 0; i < jsonRes.length; i++) {
    Map temp = jsonRes[i]['node'];
    if (temp.keys.contains('bodyText')) {
      issueTimeline.add(IssueComment(null, issue, temp['id'], temp['url'], "",
          temp['author']['login'], temp['bodyText']));
    } else if (temp.keys.contains('message')) {
      if (temp['author']['user'] == null) {
        issueTimeline.add(Commit(
          null,
          issue,
          temp['id'],
          temp['url'],
          "",
          "",
          temp['message'],
        ));
      } else {
        issueTimeline.add(Commit(
          null,
          issue,
          temp['id'],
          temp['url'],
          "",
          temp['author']['user']['login'],
          temp['message'],
        ));
      }
    } else if (temp.keys.contains('label')) {
      issueTimeline.add(LabeledEvent(
          null,
          issue,
          temp['id'],
          temp['label']['url'],
          "",
          temp['actor']['login'],
          temp['label']['name']));
    }
  }
  return issueTimeline;
}

// parseUserRepos parses the result from the GraphQL query for fetching the repositories for a user
List<Repository> parseUserRepos(String resBody) {
  List jsonRes =
    json.decode(resBody)['data']['viewer']['repositories']['nodes'];
  
  List<Repository> repos = [];

  for (var i = 0; i < jsonRes.length; i++) {
    repos.add(Repository(jsonRes[i]['name'], jsonRes[i]['nameWithOwner']));
  }

  return repos;
}

// parseAddedComment parses the response received after calling addComment mutation
IssueComment parseAddedComment(String resBody, PullRequest pr, Issue issue){
  Map jsonRes = json.decode(resBody)['data']['addComment']['commentEdge']['node'];
  Map jsonTemp = json.decode(resBody)['data']['addComment'];

  return IssueComment(pr, issue, "", jsonRes['url'], 
  jsonTemp['subject']['id'], jsonRes['author']['login'], jsonRes['bodyText']);
}