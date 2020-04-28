package httpapi.authz
import input

default allow = false

rl_permissions := {
    "reader": [{"action": "s3:ListBucket"},
              {"action": "s3:GetObject"},
              {"action": "s3:ListAllMyBuckets"}],
    "user": [{"action": "s3:CreateBucket"},
              {"action": "s3:DeleteBucket"},
              {"action": "s3:DeleteObject"},
              {"action": "s3:GetObject"},
              {"action": "s3:ListAllMyBuckets"},
              {"action": "s3:GetBucketObjectLockConfiguration"},
              {"action": "s3:ListBucket"},
              {"action": "s3:PutObject"}],
    "shared": [{"action": "s3:ListAllMyBuckets"},
               {"action": "s3:GetObject"},
               {"action": "s3:ListBucket" }],
    "admin": [{"action": "admin:ServerTrace"},
              {"action": "s3:CreateBucket"},
              {"action": "s3:DeleteBucket"},
              {"action": "s3:DeleteBucket"},
              {"action": "s3:DeleteObject"},
              {"action": "s3:GetObject"},
              {"action": "s3:ListAllMyBuckets"},
              {"action": "s3:ListBucket"},
              {"action": "s3:PutObject"}],
}

allow {
  root = ["minimal-tenant1", "pachyderm-tenant1", "premium-tenant1"]
  input.account == root[_]
}

allow {
  startswith(input.account, "read-all-")
  permissions := rl_permissions["reader"]
  p := permissions[_]
  p == {"action": input.action}
}

allow {
  admins = ["will.hearn@cloud.statcan.ca", "zachary.seguin@cloud.statcan.ca"]
  input.claims.preferred_username == admins[_]
  permissions := rl_permissions["admin"]
  p := permissions[_]
  p == {"action": input.action}
}

allow {
  username := split(lower(input.claims.preferred_username),"@")[0]
  input.bucket == username
  # input.claims.organisation_name == "daaas"
  permissions := rl_permissions["user"]
  p := permissions[_]
  p == {"action": input.action}
}

allow {
  username := split(lower(input.claims.preferred_username),"@")[0]
  ref := input.conditions.Referer[_]
  url := concat("/", ["^http://.*:9000/minio/shared",username,".*$"] )
  re_match( url , ref)
  # input.claims.organisation_name == "daaas"
  permissions := rl_permissions["user"]
  p := permissions[_]
  p == {"action": input.action}
}

allow {
  input.bucket == "shared"
  permissions := rl_permissions["shared"]
  p := permissions[_]
  p == {"action": input.action}
}
