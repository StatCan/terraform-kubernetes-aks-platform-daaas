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
              {"action": "s3:GetBucketObjectLockConfiguration"},
              {"action": "s3:GetObject"},
              {"action": "s3:ListAllMyBuckets"},
              {"action": "s3:ListBucket"},
              {"action": "s3:PutObject"}],
}

allow {
  root = ["minimal-tenant1", "pachyderm-tenant1", "premium-tenant1"]
  input.account == root[_]
}

# Allow profile access
allow {
  profile := regex.find_all_string_submatch_n("^profile-(.*)-[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}$", input.account, 1)
  input.bucket == profile[0][1]
  permissions := rl_permissions["user"]
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
  username := replace(split(lower(input.claims.preferred_username),"@")[0], ".", "-")
  input.bucket == username
  permissions := rl_permissions["user"]
  p := permissions[_]
  p == {"action": input.action}
}

allow {
  username := replace(split(lower(input.claims.preferred_username),"@")[0], ".", "-")
  input.bucket == "shared"
  url := concat("/", [username,".*$"] )
  re_match( url , input.object)
  permissions := rl_permissions["user"]
  p := permissions[_]
  p == {"action": input.action}
}

# Allow shared for profile access key
allow {
  profile := regex.find_all_string_submatch_n("^profile-(.*)-[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}$", input.account, 1)
  username = profile[0][1]
  input.bucket == "shared"
  url := concat("/", [username,".*$"] )
  re_match(url , input.object)
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
