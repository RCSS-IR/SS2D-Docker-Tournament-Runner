import sys

if len(sys.argv) < 4:
    print('python teams group starter/major test/league/cup')
    exit()
teams_file = sys.argv[1]
group = sys.argv[2]
starter_major = sys.argv[3]
config = sys.argv[4]

file = open(teams_file, 'r')
teams = []
for t in file.readlines():
    teams.append(t.lstrip().rstrip())

output = open(f'group_{group}_games', 'w')
for i in range(len(teams) - 1):
    z = 0
    for j in range(i + 1, len(teams)):
        print(teams[j], teams[z], group, starter_major, config)
        output.write(f'{group} {starter_major} {config} {teams[j]} {teams[z]}\n')
        z += 1

