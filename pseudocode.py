## These are the memory IO things
puzzle_at_address = 0xhFFFFFF
unfreeze_bot_address = 0xhFFFFF2

## These are our user defined properties to make sense of the world
isFrozen = false
stationUp = false
stationDown = true
lowAltWarn = false
puzzleReady = false
safe_x = 90
wait_point_x = 150
wait_point_y = 120
botEnergyWarn = 100
freeze_puzzle = []
puzzle = []

def main():
    if isFrozen:
        unfreezeBot()
    elif stationUp:
        chaseStation()
    elif stationDown:
        ## Do something about puzzle solving for energy
    elif bot_energy <= botEnergyWarn:
        energizePuzzle()
    elif enemy_bot_x <= lowAltWarn:
        evilPuzzle()
    else:
        findNearest()
        if nearest_x == bot_x && nearest_y == bot_y:
            pickup()
        else:
            move(nearest_x, nearest_y)

def findNearest():
    ## Find the nearest however we wanna do it
    nearest_x = xResult()
    nearest_y = yResult()

def unfreezeBot():
    unfreeze_bot_address = solvePuzzle(freeze_puzzle)
    return

def energizePuzzle():
    setEnergizeBits()
    solvePuzzle()
    return

def evilPuzzle():
    setEvilBits()
    solvePuzzle()
    return

def solvePuzzle(puzzle):
    ## Whatever else computation we might do to solve the damn thing here...

def standbyPuzzle():
    while bot_x != safe_x:
        if isFrozen:                    ## If we get frozen in the loop, we escape to handle it
            unfreezeBot()
        move(safe_x, bot_y)
    bot_velocity = 3                    ## Whatever velocity needed to stabilize

def standbyStation():
    while x != wait_point_x && y != wait_point_y :
        if isFrozen:                    ## If we get frozen in the loop, we escape to handle it
            unfreezeBot()
        x = wait_point_x
        y = wait_point_y
        move(x, y)
    bot_velocity = 3                    ## Whatever velocity needed to stabilize

## Also known as Chase
def move(x, y):
    ## However we want to handle move code
    return

def interruptHandler():
    def timer():
        return null
    def station_enter():
        acknowledge()
        stationUp = true
        stationDown = false
        return
    def station_exit():
        acknowledge()
        stationUp = false
        stationDown = true
        return
    def puzzle_ready():
        acknowledge()
        puzzleReady = true
        return
    def frozen():
        acknowledge()
        freeze_puzzle = puzzle_at_address
        isFrozen = true
        return