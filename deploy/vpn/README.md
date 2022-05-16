# VPN Admin Instructions

Create the OpenVPN config file by running the `enroll_client.sh` script (see requirements below). Replace "example@meltano.com" with the user's actual email address.

    ./enroll_client.sh example@meltano.com

A 1Password link will be printed. It can only be accessed by the provided email address. Share this link with the user via Slack, email, etc. With that link they will be able to access the password for the zip file produced by the script. Also send them the zip file via Slack, email, etc.

## Requirements

In order to run `enroll_client.sh`, the following requirements must be satisfied:

- [The 1Password CLI must be installed](https://developer.1password.com/docs/cli/install-server/)
- [The 1Password CLI must be signed-in](https://developer.1password.com/docs/cli/sign-in-manually)
- `git` must be installed
- [The AWS CLI must be installed](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- The AWS CLI profile `tf_data` must be configured

# VPN New User Instructions

1. Request access as described in the handbook: https://handbook.meltano.com/data-team/#data-vpn-enrollment
2. Access the provided 1Password link, and obtain the password for the zipped OpenVPN config.
3. Download the provided zip file. Unzip it using the password obtained in step 1. This file contains your private key. Be mindful of its permissions.
4. Download the VPN client https://aws.amazon.com/vpn/client-vpn-download/
5. Open the VPN client GUI. Navigate to: File -> Manage Profiles -> Add Profile
6. Display name = "Data Prod", navigate to path of unzipped `.ovpn` file
7. Save bookmarks for services (Airflow, Superset, Meltano UI)
8. Airflow and Meltano UI have no auth (please dont break anything until we add auth), Superset has read only credentials in 1Pass "Superset - Public"
9. Request a developer user for Superset if needed. The public user is read only.
10. Request USERDEV access in the Squared to be able to run dbt/superset against Snowflake in a isolated dev environment.

Check out:
- Airflow - http://internal-095a2699-meltano-airflowai-4cc5-148256298.us-east-1.elb.amazonaws.com/
- Superset - http://internal-095a2699-meltano-superset-608a-2127736714.us-east-1.elb.amazonaws.com/
- Meltano UI - http://internal-095a2699-meltano-meltanoin-c567-323473377.us-east-1.elb.amazonaws.com/
