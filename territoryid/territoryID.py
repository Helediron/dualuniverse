import math 
import numpy as np
import numpy.linalg as la
from scipy.spatial.transform import Rotation as R
import sys

def numHexesOnEdge(numTiles):
    return int(math.sqrt(numTiles - 2) / math.sqrt(30)) - 1

def numTiles(numHexesOnEdge):
    return 32 + 60 * numHexesOnEdge + 30 * (numHexesOnEdge**2)

def getHexes(numTiles):
    golden = (1.0 + math.sqrt(5.0)) / 2.0
    hexes_on_edge = numHexesOnEdge(numTiles)
    r2d = 180.0 / np.pi

    lat_top =  58.282525588538995
    lat_upper_mid =  31.717474411460998
    lat_lower_mid = -31.717474411460998
    lat_bottom = -58.282525588538995

    lon_8 = 31.717474411460998
    lon_9 = - lon_8
    lon_10 = lon_8 - 180.0
    lon_11 = 180.0 - lon_8

    # coordinates of pentagon tiles 1...11 in the form (lat, lon)
    pentagon_tiles = [
        np.array((lat_upper_mid, 90.0)),
        np.array((lat_lower_mid, 90.0)),
        np.array((lat_lower_mid, -90.0)),
        np.array((lat_upper_mid, -90.0)),
        np.array((lat_top, 0.0)),
        np.array((lat_top, 180.0)),
        np.array((lat_bottom, 180.0)),
        np.array((lat_bottom, 0.0)),
        np.array((0.0, lon_8)),
        np.array((0.0, lon_9)),
        np.array((0.0, lon_10)),
        np.array((0.0, lon_11))
    ]

    def angleBetween(v1, v2):
        return math.acos(np.round(v1.dot(v2) / (la.norm(v1) * la.norm(v2)), decimals=7))

    # ISO ISO 80000-2:2019
    # x: front; y: right; z: up
    def projectOntoSphere(vec):
        vec_xy = np.array((vec[0], vec[1]))
        vec_xy_withz = np.array((vec[0], vec[1], 0.0))
        lat = angleBetween(vec, vec_xy_withz) * r2d
        if vec[2] < 0:
            lat *= -1
        lon = angleBetween(vec_xy, np.array([1.0, 0.0])) * r2d
        if vec[1] < 0:
            lon *= -1
        return np.array((lat, lon))

    def coordsFromSphere(sph):
        lat, lon = sph
        vec = np.array([1.0, 0.0, 0.0])
        rot = R.from_euler("ZY", [lon, -lat], degrees=True)
        [vec] = rot.apply([vec])
        return vec

    def distributePointsBetween(sph1, sph2, numpoints, includeEndpoints=False):
        # use convex combinations
        if includeEndpoints:
            lams = np.linspace(0.0, 1.0, numpoints)
        else:
            lams = np.linspace(0.0, 1.0, numpoints + 2)[1 : (numpoints + 1)]
        v1 = coordsFromSphere(sph1)
        v2 = coordsFromSphere(sph2)
        vecs = [(1 - lam) * v1 + lam * v2 for lam in lams]
        return np.array([projectOntoSphere(v) for v in vecs])

    def center(sphs):
        center = np.zeros((3))
        for sph in sphs:
            vec = coordsFromSphere(sph)
            center += vec / len(sphs)
        return projectOntoSphere(center)
        '''
        center = np.zeros((2))
        for sph in sphs:
            center += sph / len(sphs)
        return center
        '''

    # also for pentagons
    class Hex:
        def __init__(self, sph, TID):
            # spherical coordinates of center point
            self.sph = sph
            # territory ID
            self.TID = TID
            self.neighbors = []
        def addNeighborLeft(self, neighbor):
            self.neighbors.insert(0, neighbor)
        def addNeighborRight(self, neighbor):
            self.neighbors.append(neighbor)

    class Line:
        def __init__(self, lineNum, fromHex, toHex, numHexesBetween):
            self.lineNum = lineNum
            self.fromHex = fromHex
            self.toHex = toHex
            self.pointsBetween = distributePointsBetween(fromHex.sph, toHex.sph, numHexesBetween)
            self.hexesBetween = [Hex(sph, 12 + lineNum * hexes_on_edge + i) for i, sph in enumerate(self.pointsBetween)]
            self.fullLine = [self.fromHex]
            self.fullLine.extend(self.hexesBetween)
            self.fullLine.extend([self.toHex])
            self.rightHexes = None
            self.leftHexes = None
        def generateConnections(self):
            for i in range(len(self.fullLine) - 1):
                leftHexes[i].addNeighborRight(self.fullLine[i])
                rightHexes[i].addNeighborRight(self.fullLine[i])
                leftHexes[i].addNeighborRight(rightHexes[i])
                rightHexes[i].addNeighborRight(leftHexes[i])
                leftHexes[i].addNeighborRight(self.fullLine[i + 1])
                rightHexes[i].addNeighborRight(self.fullLine[i + 1])
        def connectLeft(self, newHexes):
            self.leftHexes = newHexes
            if self.rightHexes != None:
                self.generateConnections()
        def connectRight(self, newHexes):
            self.rightHexes = newHexes
            if self.leftHexes != None:
                self.generateConnections()
        def isConnected(self):
            return self.rightHexes == None and self.leftHexes == None

    class Triangle:
        def __init__(self, parallelLine, lineF, lineT, triNum, lpReverse=False, lfReverse=False, ltReverse=False):
            tid = int((12) + (30 * hexes_on_edge) + triNum * ((3.0/2.0) * hexes_on_edge**2 + (3.0/2.0) * hexes_on_edge + 1))
            self.innerHexes = []
            topStart = parallelLine.fromHex.sph
            topEnd = parallelLine.toHex.sph
            topStartSecond = parallelLine.hexesBetween[0].sph
            topEndSecond = parallelLine.hexesBetween[-1].sph
            if lpReverse:
                topStart, topEnd = topEnd, topStart
                topStartSecond, topEndSecond = topEndSecond, topStartSecond
            for i in range(hexes_on_edge):
                hex_f = lineF.hexesBetween[hexes_on_edge - 1 - i if lfReverse else i].sph
                hex_t = lineT.hexesBetween[hexes_on_edge - 1 - i if ltReverse else i].sph
                # generate 3 lines
                len_top = hexes_on_edge + 1 - i
                len_mid = hexes_on_edge - i
                len_bot = hexes_on_edge - 1 - i
                if len_bot != 0:
                    # top line
                    top_start = center([topStart, topStartSecond, hex_f])
                    top_end = center([topEnd, topEndSecond, hex_t])
                    top_points = distributePointsBetween(top_start, top_end, len_top, includeEndpoints=True)
                    # bot line
                    if len_bot != 0:
                        bot_points = distributePointsBetween(hex_f, hex_t, len_bot)
                    else:
                        bot_points = []
                    # mid line
                    mid_start = center([top_points[1], bot_points[0], hex_f])
                    mid_end = center([top_points[-2], bot_points[-1], hex_t])
                    mid_points = distributePointsBetween(mid_start, mid_end, len_mid, includeEndpoints=True)
                    # generate IDs and hexes
                    for p in top_points:
                        self.innerHexes.append(Hex(p, tid))
                        tid += 1
                    for p in mid_points:
                        self.innerHexes.append(Hex(p, tid))
                        tid += 1
                    for p in bot_points:
                        self.innerHexes.append(Hex(p, tid))
                        tid += 1
                    # new start hexes
                    topStart = hex_f
                    topEnd = hex_t
                    topStartSecond = bot_points[0]
                    topEndSecond = bot_points[-1]
                else:
                    # generate last hex
                    hex_f = lineF.hexesBetween[hexes_on_edge - 1 - i if lfReverse else i].sph
                    hex_t = lineT.hexesBetween[hexes_on_edge - 1 - i if ltReverse else i].sph
                    point_end = lineF.fromHex.sph if lfReverse else lineF.toHex.sph
                    last_point = center([hex_f, hex_t, point_end])
                    # generate second-last hex
                    second_last_point = center([hex_f, hex_t, topStartSecond])
                    # generate two top points
                    top_points = [center([hex_f, topStartSecond, topStart]), center([hex_t, topStartSecond, topEnd])]
                    for p in top_points:
                        self.innerHexes.append(Hex(p, tid))
                        tid += 1
                    self.innerHexes.append(Hex(second_last_point, tid))
                    tid += 1
                    self.innerHexes.append(Hex(last_point, tid))
                    tid += 1

    # register pentagons
    pentas = []
    for i, sph in enumerate(pentagon_tiles):
        pentas.append(Hex(sph, i))

    def spanLine(pentaIDFrom, pentaIDTo, lineID):
        return Line(lineID, pentas[pentaIDFrom], pentas[pentaIDTo], hexes_on_edge)


    # register lines
    lines = [
        spanLine(0, 1, 0),
        spanLine(0, 8, 1),
        spanLine(1, 8, 2),
        spanLine(0, 11, 3),
        spanLine(1, 11, 4),
        spanLine(0, 5, 5),
        spanLine(5, 11, 6),
        spanLine(0, 4, 7),
        spanLine(4, 5, 8),
        spanLine(4, 8, 9),
        spanLine(4, 9, 10),
        spanLine(8, 9, 11),
        spanLine(7, 8, 12),
        spanLine(7, 9, 13),
        spanLine(1, 7, 14),
        spanLine(6, 7, 15),
        spanLine(1, 6, 16),
        spanLine(6, 11, 17),
        spanLine(10, 11, 18),
        spanLine(6, 10, 19),
        spanLine(5, 10, 20),
        spanLine(3, 5, 21),
        spanLine(3, 10, 22),
        spanLine(3, 4, 23),
        spanLine(3, 9, 24),
        spanLine(2, 3, 25),
        spanLine(2, 9, 26),
        spanLine(2, 7, 27),
        spanLine(2, 6, 28),
        spanLine(2, 10, 29)
    ]

    # register triangles
    tris = [
        Triangle(lines[1], lines[0], lines[2], 0, ltReverse=True),
        Triangle(lines[4], lines[0], lines[3], 1, lfReverse=True, ltReverse=True),
        Triangle(lines[3], lines[5], lines[6], 2, ltReverse=True),
        Triangle(lines[5], lines[7], lines[8], 3, ltReverse=True),
        Triangle(lines[7], lines[1], lines[9], 4),
        Triangle(lines[10], lines[9], lines[11], 5, ltReverse=True),
        Triangle(lines[12], lines[13], lines[11], 6),
        Triangle(lines[2], lines[14], lines[12], 7, ltReverse=True),
        Triangle(lines[14], lines[16], lines[15], 8, ltReverse=True),
        Triangle(lines[16], lines[4], lines[17], 9),
        Triangle(lines[19], lines[17], lines[18], 10),
        Triangle(lines[20], lines[18], lines[6], 11, lpReverse=True),
        Triangle(lines[21], lines[22], lines[20], 12),
        Triangle(lines[23], lines[21], lines[8], 13),
        Triangle(lines[24], lines[23], lines[10], 14, ltReverse=True),
        Triangle(lines[26], lines[25], lines[24], 15, ltReverse=True),
        Triangle(lines[27], lines[26], lines[13], 16),
        Triangle(lines[28], lines[27], lines[15], 17),
        Triangle(lines[29], lines[28], lines[19], 18, ltReverse=True),
        Triangle(lines[25], lines[29], lines[22], 19),
    ]

    # put it together
    all_hexes = []
    for h in pentas:
        all_hexes.append(h)
    for l in lines:
        all_hexes.extend(l.hexesBetween)
    for t in tris:
        all_hexes.extend(t.innerHexes)

    return all_hexes

printAll = True

def printCoords(inId, sph):
    print("{} {:.2f} {:.2f}".format(inId, sph[0], sph[1]))

planetId = 0
argInd = 2
if len(sys.argv) < 2:
    print("Usage: territoryId <numterritories> [<tilenum>...]")
    print("  Prints coordinates of a hex on planet: id lat lon.")
    print("  If tilenum is missing it prints all hexes.")
    exit(1)
if len(sys.argv) > 2:
    printAll = False

numTiles = int(sys.argv[1])
hexes = getHexes(numTiles)
try:
    if printAll:
        for i in range(0, len(hexes)):
            printCoords(i, hexes[i].sph)
    else:
        while argInd < len(sys.argv):
            inId = int(sys.argv[argInd])
            argInd = argInd + 1
            if inId < 0 or inId > numTiles:
                print("We ain't found shit.")
            else:
                printCoords(inId, hexes[inId].sph)
except Exception as inst:
    print(type(inst))
    print(inst.args)
