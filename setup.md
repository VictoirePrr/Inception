Complete Setup for New VM:

Create VM with Ubuntu, username: victoire ✅

Install Docker & Docker Compose:
sudo apt-get update
sudo apt-get install docker.io docker-compose -y
sudo usermod -aG docker victoire

Clone your GitHub repo:
git clone <your-repo-url>
cd Inception

Create data directories:
mkdir -p /home/victoire/data/mariadb
mkdir -p /home/victoire/data/wordpress

Add domain to /etc/hosts:
echo "127.0.0.1 vicperri.42.fr" | sudo tee -a /etc/hosts