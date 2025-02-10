resource "aws_dynamodb_table" "dynamo" {
  name         = "payments"
  billing_mode = "PAY_PER_REQUEST"
  on_demand_throughput {
    max_read_request_units  = 1
    max_write_request_units = 1
  }
  hash_key  = "PK"
  range_key = "SK"
  attribute {
    name = "PK"
    type = "S"
  }
  attribute {
    name = "SK"
    type = "S"
  }
  point_in_time_recovery {
    enabled = false
  }
}