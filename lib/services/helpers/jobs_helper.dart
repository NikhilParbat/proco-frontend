import 'dart:convert'; // For encoding data to JSON
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as https;
import 'package:proco/models/request/jobs/create_job.dart';
import 'package:proco/models/response/jobs/swipe_res_model.dart';
import 'package:proco/models/response/jobs/get_job.dart';
import 'package:proco/models/response/jobs/jobs_response.dart';
import 'package:proco/services/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/response/jobs/match_res_model.dart';

class JobsHelper {
  static https.Client client = https.Client();

  static Future<List<JobsResponse>> getFilteredJobs(String agentId) async {
    try {
      final requestHeaders = {'Content-Type': 'application/json'};
      final url = Config.url( '${Config.jobs}/filtered/$agentId');
      final response = await client.get(url, headers: requestHeaders);

      if (response.statusCode == 200) {
        return jobsResponseFromJson(response.body);
      } else {
        throw Exception('Failed to get filtered jobs');
      }
    } catch (e, s) {
      debugPrint('Error Occurred: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  static Future<List<JobsResponse>> getFilteredJobsPaged(
    String agentId,
    int page,
    int limit, {
    List<String> excludeIds = const [],
  }) async {
    try {
      final requestHeaders = {'Content-Type': 'application/json'};
      final queryParams = <String, String>{
        'page': '$page',
        'limit': '$limit',
        if (excludeIds.isNotEmpty) 'excludeIds': excludeIds.join(','),
      };
      final url = Config.url('${Config.jobs}/filtered/$agentId', queryParams);
      final response = await client.get(url, headers: requestHeaders);
      if (response.statusCode == 200) {
        return jobsResponseFromJson(response.body);
      } else {
        throw Exception('Failed to get filtered jobs (page $page)');
      }
    } catch (e, s) {
      debugPrint('Error Occurred: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  static Future<List<JobsResponse>> getJobs() async {
    try {
      final requestHeaders = {'Content-Type': 'application/json'};
      final url = Config.url( Config.jobs);
      final response = await client.get(url, headers: requestHeaders);

      if (response.statusCode == 200) {
        return jobsResponseFromJson(response.body);
      } else {
        throw Exception('Failed to get the jobs');
      }
    } catch (e, s) {
      debugPrint('Error Occurred: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  static Future<List<JobsResponse>> getJobsPaged(int page, int limit) async {
    try {
      final requestHeaders = {'Content-Type': 'application/json'};
      final url = Config.url( Config.jobs, {
        'page': '$page',
        'limit': '$limit',
      });
      final response = await client.get(url, headers: requestHeaders);
      if (response.statusCode == 200) {
        return jobsResponseFromJson(response.body);
      } else {
        throw Exception('Failed to get jobs (page $page)');
      }
    } catch (e, s) {
      debugPrint('Error Occurred: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  static Future<GetJobRes> getJob(String jobId) async {
    try {
      final requestHeaders = {'Content-Type': 'application/json'};
      final url = Config.url( '${Config.jobs}/$jobId');
      final response = await client.get(url, headers: requestHeaders);

      if (response.statusCode == 200) {
        return getJobResFromJson(response.body);
      } else {
        throw Exception('Failed to get a job');
      }
    } catch (e, s) {
      debugPrint('Error Occurred: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  static Future<List<JobsResponse>> getUserJobs(String agentId) async {
    final requestHeaders = {'Content-Type': 'application/json'};
    final url = Config.url( '${Config.jobs}/user/$agentId');

    final response = await client.get(url, headers: requestHeaders);

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      List data;
      if (decoded is List) {
        data = decoded;
      } else {
        if (decoded['success'] != true) {
          throw Exception(decoded['message'] ?? 'Failed to load user jobs');
        }
        data = decoded['data'] ?? [];
      }

      if (data.isEmpty) {
        debugPrint('No jobs found for user: $agentId');
        return [];
      }

      List<JobsResponse> jobs = data
          .map((job) => JobsResponse.fromJson(job))
          .toList();

      List<String> jobIds = jobs.map((job) => job.id).toList();
      await saveJobIdsToPrefs(jobIds);
      await _saveUserJobsCache(agentId, data); // persist full job data

      return jobs;
    } else {
      debugPrint('Failed to load jobs: ${response.statusCode}');
      throw Exception('Failed to load user jobs');
    }
  }

  // Save all job IDs in SharedPreferences
  static Future<void> saveJobIdsToPrefs(List<String> jobIds) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('savedJobIds', jobIds);
    debugPrint("Saved job IDs: $jobIds");
  }

  // Persist full job list for instant display after login
  static Future<void> _saveUserJobsCache(String agentId, List data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userJobsCache_$agentId', jsonEncode(data));
  }

  // Read cached jobs — returns empty list if no cache exists
  static Future<List<JobsResponse>> getCachedUserJobs(String agentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('userJobsCache_$agentId');
      if (jsonStr == null) return [];
      final List data = jsonDecode(jsonStr);
      return data
          .map((e) => JobsResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Home-feed cache (used for instant card preloading) ─────────────────────
  static Future<void> saveJobsCache(
    String userId,
    List<JobsResponse> jobs,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jobs.map((j) => j.toJson()).toList();
    await prefs.setString('jobsFeedCache_$userId', jsonEncode(data));
  }

  static Future<List<JobsResponse>> getCachedJobs(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('jobsFeedCache_$userId');
      if (jsonStr == null) return [];
      final List data = jsonDecode(jsonStr);
      return data
          .map((e) => JobsResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> setCurrentJobId(String jobId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentJobId', jobId);
    debugPrint("Current job set to: $jobId");
  }

  static Future<JobsResponse> getRecent() async {
    final requestHeaders = <String, String>{'Content-Type': 'application/json'};

    final url = Config.url( Config.jobs, {'new': 'true'});
    final response = await client.get(url, headers: requestHeaders);

    if (response.statusCode == 200) {
      final jobsList = jobsResponseFromJson(response.body);

      final recent = jobsList.first;
      return recent;
    } else {
      throw Exception('Failed to get the jobs');
    }
  }

  //SEARCH
  static Future<List<JobsResponse>> searchJobs(String searchQeury) async {
    final requestHeaders = <String, String>{'Content-Type': 'application/json'};

    final url = Config.url( '${Config.search}/$searchQeury');
    final response = await client.get(url, headers: requestHeaders);

    if (response.statusCode == 200) {
      final jobsList = jobsResponseFromJson(response.body);
      return jobsList;
    } else {
      throw Exception('Failed to get the jobs');
    }
  }

  static Future<JobsResponse> createJob(
    CreateJobsRequest model, {
    File? imageFile,
  }) async {
    try {
      final url = Config.url( Config.jobs);

      final request = https.MultipartRequest('POST', url);

      // Text fields
      request.fields['title'] = model.title;
      request.fields['agentId'] = model.agentId;
      request.fields['company'] = model.company;
      request.fields['description'] = model.description;
      request.fields['salary'] = model.salary;
      request.fields['period'] = model.period;
      request.fields['hiring'] = model.hiring.toString();
      request.fields['contract'] = model.contract;
      request.fields['domain'] = model.domain;
      request.fields['opportunityType'] = model.opportunityType;
      request.fields['location'] = model.location;
      request.fields['latitude'] = model.latitude.toString();
      request.fields['longitude'] = model.longitude.toString();

      request.fields['requirements'] = jsonEncode(model.requirements);

      // Image file (optional)
      if (imageFile != null) {
        request.files.add(
          await https.MultipartFile.fromPath('image', imageFile.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await https.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = json.decode(response.body);
        final data = (body is Map && body.containsKey('data'))
            ? body['data']
            : body;
        return JobsResponse.fromJson(data as Map<String, dynamic>);
      } else {
        final body = json.decode(response.body);
        final message = (body is Map && body.containsKey('message'))
            ? body['message']
            : response.body;
        throw Exception(message);
      }
    } catch (e, s) {
      debugPrint('Error Occurred: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  static Future<void> updateJob(
    String jobId,
    Map<String, dynamic> jobData,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var token = prefs.getString('token');
      final url = Config.url( '${Config.jobs}/$jobId');
      final response = await client.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'token': 'Bearer $token', // Include the token here
        },
        body: jsonEncode(jobData),
      );

      if (response.statusCode != 200) {
        debugPrint(
          'Failed to update job: ${response.statusCode} - ${response.body}',
        );
        throw Exception('Failed to update the job');
      }
    } catch (e, s) {
      debugPrint('Error Occurred: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  static Future<void> deleteJob(String jobId) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    // debugPrint("Deleting with Token: $token"); // Use this to verify if token exists

    final url = Config.url( '${Config.jobs}/$jobId');
    final response = await client.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'token': 'Bearer $token', // Ensure 'Bearer ' has a space after it
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      debugPrint(
        "Failed to delete job: ${response.statusCode} - ${response.body}",
      );
      throw Exception('Failed to delete the job');
    }
  }

  // static Future<List<SwipedRes>> getSwipededUsersId(String jobId) async {
  //   final requestHeaders = {'Content-Type': 'application/json'};
  //   final url = Config.url( '${Config.jobs}/user/swipe/$jobId');
  //   final response = await client.get(url, headers: requestHeaders);
  //   debugPrint("Response Received $response");

  //   if (response.statusCode == 200) {
  //     final Map<String, dynamic> data = json.decode(response.body);

  //     if (data.isEmpty || !data.containsKey('swipedUsers')) {
  //       debugPrint('No swiped users found for this job: $jobId');
  //       debugPrint("No swiped users");
  //       return [];
  //     }
  //     List<SwipedRes> swipedUsers = List<SwipedRes>.from(data['swipedUsers']);
  //     return swipedUsers;
  //   } else {
  //     debugPrint('Failed to load swiped users: ${response.statusCode}');
  //     throw Exception('Failed to load swiped users');
  //   }
  // }
  static Future<List<SwipedRes>> getSwipededUsersId(String jobId) async {
    try {
      final requestHeaders = {'Content-Type': 'application/json'};
      final url = Config.url( '${Config.swipe}/$jobId');

      final response = await client.get(url, headers: requestHeaders);

      if (response.statusCode == 200) {
        debugPrint("Response Received: ${response.body}");

        final decoded = json.decode(response.body);

        // ✅ Handle wrapper
        if (decoded['success'] != true) {
          throw Exception(decoded['message'] ?? 'Failed to fetch swiped users');
        }

        final List data = decoded['data'] ?? [];

        if (data.isEmpty) {
          debugPrint('No swiped users found for this job: $jobId');
          return [];
        }

        // ✅ Convert properly
        List<SwipedRes> swipedUsers = data
            .map((user) => SwipedRes.fromJson(user))
            .toList();

        return swipedUsers;
      } else {
        debugPrint('Failed to load swiped users: ${response.statusCode}');
        throw Exception('Failed to load swiped users');
      }
    } catch (e) {
      debugPrint('Error fetching swiped users: $e');
      return [];
    }
  }

  static Future<void> undoSwipe(String jobId, String userId) async {
    final url = Config.url( '${Config.swipe}/undo');
    try {
      await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'jobId': jobId, 'userId': userId}),
      );
    } catch (e) {
      debugPrint('Error undoing swipe: $e');
    }
  }

  static Future<void> addSwipedUsers(
    String jobId,
    String userId,
    String action,
  ) async {
    final requestHeaders = {'Content-Type': 'application/json'};
    final url = Config.url( Config.swipe);

    try {
      final requestBody = json.encode({
        'jobId': jobId,
        'userId': userId,
        'action': action,
      });
      final response = await client.post(
        url,
        headers: requestHeaders,
        body: requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('User $userId added to swiped users for job $jobId');
      } else {
        debugPrint(
          'Failed to add swiped user: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Error adding swiped user: $e');
    }
  }

  static Future<List<MatchedRes>> getMatchedUsersId(String jobId) async {
    try {
      final requestHeaders = {'Content-Type': 'application/json'};
      final url = Config.url( '${Config.matches}/$jobId');

      final response = await client.get(url, headers: requestHeaders);

      if (response.statusCode == 200) {
        debugPrint("Response Received: ${response.body}");

        final List<dynamic> data = json.decode(response.body);

        if (data.isEmpty) {
          debugPrint('No matched users found for this job: $jobId');
          debugPrint("No matched users found");
          return [];
        }

        //Convert the List<dynamic> into List<MatchedRes>
        List<MatchedRes> matchedUsers = data
            .map((user) => MatchedRes.fromJson(user))
            .toList();

        return matchedUsers;
      } else {
        debugPrint('Failed to load matched users: ${response.statusCode}');
        throw Exception('Failed to load matched users');
      }
    } catch (e) {
      debugPrint('Error fetching matched users: $e');
      debugPrint("Exception: $e");
      return []; // Return an empty list in case of an error
    }
  }

  static Future<void> addMatchedUsers(String jobId, String userId) async {
    final requestHeaders = {'Content-Type': 'application/json'};
    final url = Config.url( Config.matches);
    debugPrint("jobId: $jobId");
    debugPrint("userId: $userId");

    try {
      final requestBody = json.encode({
        'jobId': jobId,
        'userId': userId,
        'action': 'right',
      });
      final response = await client.post(
        url,
        headers: requestHeaders,
        body: requestBody,
      );

      debugPrint('Response: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('User $userId added to match users for job $jobId');
      } else {
        debugPrint(
          'Failed to add matched user: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Error adding matched user: $e');
    }
  }
}
