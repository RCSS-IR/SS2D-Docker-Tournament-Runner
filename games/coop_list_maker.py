import sys
import itertools

if len(sys.argv) < 5:
    print('python teams group starter/major test/league/cup')
    exit()
teams_file = sys.argv[1]
group = sys.argv[2]
starter_major = sys.argv[3]
config = sys.argv[4]

file = open(teams_file, 'r')
teams = [t.strip() for t in file.readlines()]

output = open(f'group_{group}_games.txt', 'w')

def generate_matchups(teams):
    pairs = list(itertools.combinations(teams, 2))
    matchups = set()

    for p1 in pairs:
        for p2 in pairs:
            if p1 != p2 and not set(p1) & set(p2):
                matchup1 = (tuple(sorted(p1)), tuple(sorted(p2)))
                matchup2 = (tuple(sorted(p1)), tuple(sorted(p2, reverse=True)))
                matchup3 = (tuple(sorted(p1, reverse=True)), tuple(sorted(p2)))
                matchup4 = (tuple(sorted(p1, reverse=True)), tuple(sorted(p2, reverse=True)))
                matchups.add(matchup1)
                matchups.add(matchup2)
                matchups.add(matchup3)
                matchups.add(matchup4)

    formatted_matchups = []
    for matchup in matchups:
        p1, p2 = matchup
        formatted_matchups.append((p1[0], p1[1], p2[0], p2[1]))

    return formatted_matchups

all_matchups = generate_matchups(teams)

for matchup in all_matchups:
    teams_left = f"{matchup[0]}_{matchup[1]}"
    teams_right = f"{matchup[2]}_{matchup[3]}"
    output_line = f"{group} {starter_major} {config} {teams_left} {teams_right}\n"
    output.write(output_line)

output.close()

# print(f"TN: {num_games}")

# for i in range(len(teams) - 1):
#     z = 0
#     for j in range(i + 1, len(teams)):
#         print(teams[j], teams[z], group, starter_major, config)
#         output.write(f'{group} {starter_major} {config} {teams[j]} {teams[z]}\n')
#         z += 1

