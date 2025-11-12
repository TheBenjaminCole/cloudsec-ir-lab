#################
# Athena & OpenSearch
#################

#resource "aws_athena_database" "logs" {
# name = "cloudsec_ir_lab_logs"
#bucket = aws_s3_bucket.cloudtrail_logs.bucket
#}

#resource "aws_opensearch_domain" "sec_lab" {
#domain_name = "cloudsec-ir-lab"
#engine_version = "OpenSearch_2.9"
#cluster_config {
#instance_type = "t3.small.search"
#instance_count = 1
#}
#ebs_options {
#ebs_enabled = true
#volume_size = 10
#}
#}