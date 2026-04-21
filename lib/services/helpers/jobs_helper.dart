import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as https;
import 'package:proco/models/request/jobs/create_job.dart';
import 'package:proco/models/response/api_response.dart';
import 'package:proco/models/response/jobs/get_job.dart';
import 'package:proco/models/response/jobs/jobs_response.dart';
import 'package:proco/models/response/jobs/match_res_model.dart';
import 'package:proco/models/response/jobs/swipe_res_model.dart';
import 'package:proco/services/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JobsHelper {
  static https.Client client = https.Client();

  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'token': 'Bearer $token',
    };
  }

  // ─── Get filtered jobs (all pages) ────────────────────────────────────────

  static Future<ApiResponse<List<JobsResponse>>> getFilteredJobs(
    String agentId,
  ) async {
    try {
      final headers = await _authHeaders();
      final url = Config.url('${Config.jobs}/filtered/$agentId');
      final response = await client.get(url, headers: headers);

      if (response.body.isEmpty) {
        return ApiResponse(success: false, message: 'Server is starting up, please try again');
      }
      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: 'Jobs fetched successfully',
          data: jobsResponseFromJson(response.body),
        );
      }
      final body = jsonDecode(response.body);
      return ApiResponse(success: false, message: body['message'] ?? 'Failed to get filtered jobs');
    } catch (e) {
      debugPrint('JobsHelper.getFilteredJobs error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // ─── Get filtered jobs (paginated) ────────────────────────────────────────

  static Future<ApiResponse<List<JobsResponse>>> getFilteredJobsPaged(
    String agentId,
    int page,
    int limit, {
    List<String> excludeIds = const [],
  }) async {
    try {
      final headers = await _authHeaders();
      final queryParams = <String, String>{
        'page': '$page',
        'limit': '$limit',
        if (excludeIds.isNotEmpty) 'excludeIds': excludeIds.join(','),
      };
      final url = Config.url('${Config.jobs}/filtered/$agentId', queryParams);
      final response = await client.get(url, headers: headers);

      if (response.body.isEmpty) {
        return ApiResponse(success: false, message: 'Server is starting up, please try again');
      }
      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: 'Jobs fetched successfully',
          data: jobsResponseFromJson(response.body),
        );
      }
      final body = jsonDecode(response.body);
      return ApiResponse(success: false, message: body['message'] ?? 'Failed to get filtered jobs (page $page)');
    } catch (e) {
      debugPrint('JobsHelper.getFilteredJobsPaged error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // ─── Get all jobs ──────────────────────────────────────────────────────────

  static Future<ApiResponse<List<JobsResponse>>> getJobs() async {
    try {
      final headers = await _authHeaders();
      final url = Config.url(Config.jobs);
      final response = await client.get(url, headers: headers);

      if (response.body.isEmpty) {
        return ApiResponse(success: false, message: 'Server is starting up, please try again');
      }
      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: 'Jobs fetched successfully',
          data: jobsResponseFromJson(response.body),
        );
      }
      final body = jsonDecode(response.body);
      return ApiResponse(success: false, message: body['message'] ?? 'Failed to get jobs');
    } catch (e) {
      debugPrint('JobsHelper.getJobs error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // ─── Get all jobs (paginated) ──────────────────────────────────────────────

  static Future<ApiResponse<List<JobsResponse>>> getJobsPaged(
    int page,
    int limit,
  ) async {
    try {
      final headers = await _authHeaders();
      final url = Config.url(Config.jobs, {'page': '$page', 'limit': '$limit'});
      final response = await client.get(url, headers: headers);

      if (response.body.isEmpty) {
        return ApiResponse(success: false, message: 'Server is starting up, please try again');
      }
      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: 'Jobs fetched successfully',
          data: jobsResponseFromJson(response.body),
        );
      }
      final body = jsonDecode(response.body);
      return ApiResponse(success: false, message: body['message'] ?? 'Failed to get jobs (page $page)');
    } catch (e) {
      debugPrint('JobsHelper.getJobsPaged error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // ─── Get single job ────────────────────────────────────────────────────────

  static Future<ApiResponse<GetJobRes>> getJob(String jobId) async {
    try {
      final headers = await _authHeaders();
      final url = Config.url('${Config.jobs}/$jobId');
      final response = await client.get(url, headers: headers);

      if (response.body.isEmpty) {
        return ApiResponse(success: false, message: 'Server is starting up, please try again');
      }
      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: 'Job fetched successfully',
          data: getJobResFromJson(response.body),
        );
      }
      final body = jsonDecode(response.body);
      return ApiResponse(success: false, message: body['message'] ?? 'Failed to get job');
    } catch (e) {
      debugPrint('JobsHelper.getJob error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // ─── Get jobs for a specific agent/user ───────────────────────────────────

  static Future<ApiResponse<List<JobsResponse>>> getUserJobs(
    String agentId,
  ) async {
    try {
      final headers = await _authHeaders();
      final url = Config.url('${Config.jobs}/user/$agentId');
      final response = await client.get(url, headers: headers);

      if (response.body.isEmpty) {
        return ApiResponse(success: false, message: 'Server is starting up, please try again');
      }
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        List data;
        if (decoded is List) {
          data = decoded;
        } else {
          if (decoded['success'] != true) {
            return ApiResponse(
              success: false,
              message: decoded['message'] ?? 'Failed to load user jobs',
            );
          }
          data = decoded['data'] ?? [];
        }

        final jobs = data.map((j) => JobsResponse.fromJson(j as Map<String, dynamic>)).toList();

        final jobIds = jobs.map((j) => j.id).toList();
        await saveJobIdsToPrefs(jobIds);
        await _saveUserJobsCache(agentId, data);

        return ApiResponse(
          success: true,
          message: 'User jobs fetched successfully',
          data: jobs,
        );
      }
      final body = jsonDecode(response.body);
      return ApiResponse(success: false, message: body['message'] ?? 'Failed to load user jobs');
    } catch (e) {
      debugPrint('JobsHelper.getUserJobs error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // ─── Get most recent job ───────────────────────────────────────────────────

  static Future<ApiResponse<JobsResponse>> getRecent() async {
    try {
      final headers = await _authHeaders();
      final url = Config.url(Config.jobs, {'new': 'true'});
      final response = await client.get(url, headers: headers);

      if (response.body.isEmpty) {
        return ApiResponse(success: false, message: 'Server is starting up, please try again');
      }
      if (response.statusCode == 200) {
        final list = jobsResponseFromJson(response.body);
        if (list.isEmpty) {
          return ApiResponse(success: false, message: 'No jobs found');
        }
        return ApiResponse(
          success: true,
          message: 'Recent job fetched successfully',
          data: list.first,
        );
      }
      final body = jsonDecode(response.body);
      return ApiResponse(success: false, message: body['message'] ?? 'Failed to get recent job');
    } catch (e) {
      debugPrint('JobsHelper.getRecent error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // ─── Search jobs ───────────────────────────────────────────────────────────

  static Future<ApiResponse<List<JobsResponse>>> searchJobs(
    String searchQuery,
  ) async {
    try {
      final headers = await _authHeaders();
      final url = Config.url('${Config.search}/$searchQuery');
      final response = await client.get(url, headers: headers);

      if (response.body.isEmpty) {
        return ApiResponse(success: false, message: 'Server is starting up, please try again');
      }
      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: 'Search results fetched successfully',
          data: jobsResponseFromJson(response.body),
        );
      }
      final body = jsonDecode(response.body);
      return ApiResponse(success: false, message: body['message'] ?? 'Search failed');
    } catch (e) {
      debugPrint('JobsHelper.searchJobs error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // ─── Create job ────────────────────────────────────────────────────────────

  static Future<ApiResponse<JobsResponse>> createJob(
    CreateJobsRequest model, {
    File? imageFile,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final url = Config.url(Config.jobs);
      final request = https.MultipartRequest('POST', url);

      if (token != null && token.isNotEmpty) {
        request.headers['token'] = 'Bearer $token';
      }

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
      request.fields['city'] = model.city;
      request.fields['state'] = model.state;
      request.fields['country'] = model.country;
      request.fields['latitude'] = model.latitude.toString();
      request.fields['longitude'] = model.longitude.toString();
      request.fields['requirements'] = jsonEncode(model.requirements);

      if (imageFile != null) {
        request.files.add(
          await https.MultipartFile.fromPath('image', imageFile.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await https.Response.fromStream(streamedResponse);

      if (response.body.isEmpty) {
        return ApiResponse(success: false, message: 'Server is starting up, please try again');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        final data = (body is Map && body.containsKey('data')) ? body['data'] : body;
        return ApiResponse(
          success: true,
          message: body['message'] ?? 'Job created successfully',
          data: JobsResponse.fromJson(data as Map<String, dynamic>),
        );
      }
      final body = jsonDecode(response.body);
      return ApiResponse(
        success: false,
        message: body['message'] ?? 'Failed to create job',
      );
    } catch (e) {
      debugPrint('JobsHelper.createJob error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // ─── Update job ────────────────────────────────────────────────────────────

  static Future<ApiResponse<void>> updateJob(
    String jobId,
    Map<String, dynamic> jobData,
  ) async {
    try {
      final headers = await _authHeaders();
      final url = Config.url('${Config.jobs}/$jobId');
      final response = await client.put(
        url,
        headers: headers,
        body: jsonEncode(jobData),
      );

      if (response.body.isEmpty) {
        return ApiResponse(success: false, message: 'Server is starting up, please try again');
      }
      if (response.statusCode == 200) {
        return ApiResponse(success: true, message: 'Job updated successfully');
      }
      final body = jsonDecode(response.body);
      return ApiResponse(success: false, message: body['message'] ?? 'Failed to update job');
    } catch (e) {
      debugPrint('JobsHelper.updateJob error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // ─── Delete job ────────────────────────────────────────────────────────────

  static Future<ApiResponse<void>> deleteJob(String jobId) async {
    try {
      final headers = await _authHeaders();
      final url = Config.url('${Config.jobs}/$jobId');
      final response = await client.delete(url, headers: headers);

      if (response.body.isEmpty) {
        return ApiResponse(success: false, message: 'Server is starting up, please try again');
      }
      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse(success: true, message: 'Job deleted successfully');
      }
      final body = jsonDecode(response.body);
      return ApiResponse(success: false, message: body['message'] ?? 'Failed to delete job');
    } catch (e) {
      debugPrint('JobsHelper.deleteJob error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // ─── Get swiped users for a job ───────────────────────────────────────────

  static Future<ApiResponse<List<SwipedRes>>> getSwipededUsersId(
    String jobId,
  ) async {
    try {
      final headers = await _authHeaders();
      final url = Config.url('${Config.swipe}/$jobId');
      final response = await client.get(url, headers: headers);

      debugPrint('getSwipedUsers [$jobId] body: ${response.body}');

      if (response.body.isEmpty) {
        return ApiResponse(success: false, message: 'Server is starting up, please try again');
      }
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] != true) {
          return ApiResponse(
            success: false,
            message: decoded['message'] ?? 'Failed to fetch swiped users',
          );
        }
        final List data = decoded['data'] ?? [];
        return ApiResponse(
          success: true,
          message: 'Swiped users fetched successfully',
          data: data.map((u) => SwipedRes.fromJson(u as Map<String, dynamic>)).toList(),
        );
      }
      final body = jsonDecode(response.body);
      return ApiResponse(success: false, message: body['message'] ?? 'Failed to load swiped users');
    } catch (e) {
      debugPrint('JobsHelper.getSwipededUsersId error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // ─── Undo swipe ────────────────────────────────────────────────────────────

  static Future<ApiResponse<void>> undoSwipe(
    String jobId,
    String userId,
  ) async {
    try {
      final headers = await _authHeaders();
      final url = Config.url('${Config.swipe}/undo');
      final response = await client.post(
        url,
        headers: headers,
        body: jsonEncode({'jobId': jobId, 'userId': userId}),
      );

      if (response.statusCode == 200) {
        return ApiResponse(success: true, message: 'Swipe undone successfully');
      }
      return ApiResponse(success: false, message: 'Failed to undo swipe');
    } catch (e) {
      debugPrint('JobsHelper.undoSwipe error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // ─── Record a swipe action ─────────────────────────────────────────────────

  static Future<ApiResponse<void>> addSwipedUsers(
    String jobId,
    String userId,
    String action,
  ) async {
    try {
      final headers = await _authHeaders();
      final url = Config.url(Config.swipe);
      final response = await client.post(
        url,
        headers: headers,
        body: jsonEncode({'jobId': jobId, 'userId': userId, 'action': action}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Swipe recorded: user $userId on job $jobId ($action)');
        return ApiResponse(success: true, message: 'Swipe recorded');
      }
      return ApiResponse(success: false, message: 'Failed to record swipe');
    } catch (e) {
      debugPrint('JobsHelper.addSwipedUsers error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // ─── Get matched users for a job ──────────────────────────────────────────

  static Future<ApiResponse<List<MatchedRes>>> getMatchedUsersId(
    String jobId,
  ) async {
    try {
      final headers = await _authHeaders();
      final url = Config.url('${Config.matches}/$jobId');
      final response = await client.get(url, headers: headers);

      debugPrint('getMatchedUsers [$jobId] body: ${response.body}');

      if (response.body.isEmpty) {
        return ApiResponse(success: false, message: 'Server is starting up, please try again');
      }
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List data = (decoded is Map ? decoded['data'] : decoded) ?? [];
        return ApiResponse(
          success: true,
          message: 'Matched users fetched successfully',
          data: data.map((u) => MatchedRes.fromJson(u as Map<String, dynamic>)).toList(),
        );
      }
      final body = jsonDecode(response.body);
      return ApiResponse(success: false, message: body['message'] ?? 'Failed to load matched users');
    } catch (e) {
      debugPrint('JobsHelper.getMatchedUsersId error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // ─── Record a match ────────────────────────────────────────────────────────

  static Future<ApiResponse<void>> addMatchedUsers(
    String jobId,
    String userId,
  ) async {
    try {
      final headers = await _authHeaders();
      final url = Config.url(Config.matches);
      final response = await client.post(
        url,
        headers: headers,
        body: jsonEncode({'jobId': jobId, 'userId': userId, 'action': 'right'}),
      );

      debugPrint('addMatchedUsers response: ${response.body}');

      if (response.statusCode == 200) {
        return ApiResponse(success: true, message: 'Match recorded');
      }
      return ApiResponse(success: false, message: 'Failed to record match');
    } catch (e) {
      debugPrint('JobsHelper.addMatchedUsers error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // ─── Cache utilities ───────────────────────────────────────────────────────

  static Future<void> saveJobIdsToPrefs(List<String> jobIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('savedJobIds', jobIds);
    debugPrint('Saved job IDs: $jobIds');
  }

  static Future<void> _saveUserJobsCache(String agentId, List data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userJobsCache_$agentId', jsonEncode(data));
  }

  static Future<List<JobsResponse>> getCachedUserJobs(String agentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('userJobsCache_$agentId');
      if (jsonStr == null) return [];
      final List data = jsonDecode(jsonStr);
      return data.map((e) => JobsResponse.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveJobsCache(String userId, List<JobsResponse> jobs) async {
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
      return data.map((e) => JobsResponse.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> setCurrentJobId(String jobId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentJobId', jobId);
    debugPrint('Current job set to: $jobId');
  }
}
