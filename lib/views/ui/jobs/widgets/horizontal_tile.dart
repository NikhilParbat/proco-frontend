import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:proco/models/response/jobs/jobs_response.dart';
import 'package:proco/views/common/exports.dart';
import 'package:proco/views/common/height_spacer.dart';
import 'package:proco/views/common/width_spacer.dart';

class JobHorizontalTile extends StatelessWidget {
  const JobHorizontalTile({required this.job, super.key, this.onTap});

  final void Function()? onTap;
  final JobsResponse job;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(right: 12.w),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          width: width * 0.75,
          height: height * 0.27,
          decoration: BoxDecoration(
            color: kLightGrey,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: NetworkImage(job.imageUrl),
                  ),
                  const WidthSpacer(width: 15),
                  SizedBox(
                    width: width * 0.4,
                    child: ReusableText(
                      text: job.company,
                      style: appstyle(18, kDark, FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const HeightSpacer(size: 15),
              ReusableText(
                text: job.title,
                style: appstyle(16, kDark, FontWeight.w600),
              ),
              ReusableText(
                text: job.location,
                style: appstyle(16, kDarkGrey, FontWeight.w600),
              ),
              const HeightSpacer(size: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ReusableText(
                    text: '${job.salary}/${job.period}',
                    style: appstyle(14, kDark, FontWeight.w600),
                  ),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: kLight,
                    child: const Icon(Ionicons.chevron_forward),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
