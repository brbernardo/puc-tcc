resource "aws_quicksight_data_source" "default" {
  data_source_id = "example-id"
  name           = "My Cool Data in S3"

  parameters {
    s3 {
      manifest_file_location {
        bucket = "my-bucket"
        key    = "path/to/manifest.json"
      }
    }
  }

  type = "S3"
}