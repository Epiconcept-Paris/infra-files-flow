docker cp indird/indird filesflow_files:/usr/local/bin/
docker cp indird/indird.conf filesflow_files:/etc/

docker cp indird/indird@.service filesflow_files:/etc/systemd/system
docker cp indird/indirdwake@.service filesflow_files:/etc/systemd/system
docker cp indird/indirdwake@.path filesflow_files:/etc/systemd/system