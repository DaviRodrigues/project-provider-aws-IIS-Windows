resource "aws_security_group" "windows_iis_group" {
  name        = "windows-iis-sg"
  description = "Permitir RDP, WinRM e HTTP"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5986
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "terraform-key"
  public_key = file("${path.module}/ssh/aws-pos-iis.pub")
}

resource "aws_instance" "iis_windows_2019" {
  ami                    = "ami-048608096265638fd"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.windows_iis_group.id]

  key_name = "terraform-key"

  user_data = <<-EOF
    <powershell>
    # 1. Enable WinRM service and set to automatic start
    Enable-PSRemoting -Force
    Set-Service WinRM -StartupType Automatic

    # 2. Create a self-signed certificate for HTTPS
    $Hostname = [System.Net.Dns]::GetHostByName(($env:computername)).HostName
    $Cert = New-SelfSignedCertificate -CertStoreLocation Cert:\LocalMachine\My -DnsName $Hostname

    # 3. Remove existing HTTP/HTTPS listeners to prevent conflicts
    Remove-Item -Path WSMan:\LocalHost\Listener\* -Recurse -ErrorAction SilentlyContinue

    # 4. Create new HTTPS listener using the certificate thumbprint
    New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbprint $Cert.Thumbprint -Force

    # 5. Open Windows Firewall for WinRM HTTPS (Port 5986)
    New-NetFirewallRule -DisplayName "WinRM HTTPS" -Direction Inbound -LocalPort 5986 -Protocol TCP -Action Allow

    # 6. Restart service to apply changes
    Restart-Service WinRM
    </powershell>
  EOF

  tags = {
    Name = "Trabalho-Pos-IIS-Windows"
  }
}
