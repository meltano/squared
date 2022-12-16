# Secrets/KMS

In order to safely ship secrets into production, we use RSA encryption of our `.env` file with a kms-provided `Publickey.pem` file.
Decryption is handled by the deployment using the AWS KMS API.

## Usage

To encrypt a `.env`:

```sh
meltano invoke kms:encrypt
```

This will encrypt the `.env` file at the root of our project to a `utilities/kms/secrets.yml` file using the key stored at `utilities/kms/Publickey.pem`.
The `secrets.yml` file is then safe to be committed to git as part of our repository.
We choose to keep our `Publickey.pem` file in 1Password, as an added layer of security (i.e. only Meltano engineers with 1Password access can generate a valid `secrets.yml` file for our project).

## Decryption

Decryption is expected to happen as part of deployment, however a `decrypt` command is provided for convenience.

```sh
meltano invoke kms:decrypt
```

The `decrypt` command expects a `KMS_KEY_ID` env var containing a valid KMS key ID.
This will read the file `utilities/kms/secrets.yml`, decrypt each value using AWS KMS with the given KMS key ID and output the decrypted values to a `.env` file at the root of our project directory.
The kms utility assumes AWS credentials are set in the environment (e.g. via an EC2/ECS role attachment).
