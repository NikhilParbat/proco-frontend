import 'package:proco/models/response/jobs/jobs_response.dart';

/// A single opportunity fetched from the public (no-auth) endpoint used by
/// shared links. Bundles the job with its owner's display name so the
/// read-only card needs no extra (protected) lookups.
class PublicJob {
  final JobsResponse job;
  final String ownerName;

  const PublicJob({required this.job, required this.ownerName});
}
