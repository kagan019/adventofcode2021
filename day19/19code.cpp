#include <iostream>
#include <algorithm>
#include <vector>
#include <set>
#include <tuple>
#include <fstream>
#include <random>
using namespace std;

set<tuple<int, int, int>> beacons;
vector<vector<vector<int>>> scans(27, vector<vector<int>>(26, vector<int>(3, 0)));
vector<vector<int>> scannerLocs(27, vector<int>(3, 0));
vector<bool> matchedScanners(27, false);
// RNG
random_device device;
mt19937 generator(device());
uniform_int_distribution<int> unifDist(0,25);
// Using normal vector for a 3d point/vector instead of making a new class with all operators
vector<int> operator-(const vector<int>& a, const vector<int>& b) { return {a[0] - b[0], a[1] - b[1], a[2] - b[2]}; }
vector<int> operator+(const vector<int>& a, const vector<int>& b) { return {a[0] + b[0], a[1] + b[1], a[2] + b[2]}; }
int manhatDist(vector<int> a, vector<int> b) { return abs(a[0]-b[0]) + abs(a[1]-b[1]) + abs(a[2]-b[2]); }

/* Orientation Transformation: Transform point to one of 24 possible orientations of xyz coordinate system. */
vector<vector<int>> oddFlips = {{-1,1,1}, {1,-1,1}, {1,1,-1}, {-1,-1,-1}}; // Switches handedness of xyz coordinate system
vector<vector<int>> evenFlips = {{1,-1,-1}, {-1,1,-1}, {-1,-1,1}, {1,1,1}}; // Preserves handedness
vector<vector<int>> oddPerms = {{0,2,1}, {2,1,0}, {1,0,2}}; // Switches handedness
vector<vector<int>> evenPerms = {{0,1,2}, {1,2,0}, {2,0,1}}; // Preserves handedness
vector<int> pointTransform(vector<int>& point, int orient) {
    // Preserve handedness of system using (even flip + even perm) or (odd + odd).
    // By Chinese Remainder Thm, the below (flip,perm) are distinct for all 0-11 and all 12-23.
    int flip = orient % 4;
    int perm = orient % 3;
    if (orient < 12)
        return {evenFlips[flip][0] * point[evenPerms[perm][0]],
                evenFlips[flip][1] * point[evenPerms[perm][1]],
                evenFlips[flip][2] * point[evenPerms[perm][2]]};
    else
        return {oddFlips[flip][0] * point[oddPerms[perm][0]],
                oddFlips[flip][1] * point[oddPerms[perm][1]],
                oddFlips[flip][2] * point[oddPerms[perm][2]]};
}

// See if this scanner 2 position (given an orientation) will give 12+ matches with scanner 1.
bool tryScannerLoc(vector<int>& scan2Pos, int scan1, int scan2, int orient) {
    int numMatches = 0;
    for (unsigned beac1_1 = 0; beac1_1 < scans[scan1].size(); beac1_1++) {
        for (unsigned beac2_1 = 0; beac2_1 < scans[scan2].size(); beac2_1++) {
            vector<int> scan2Pos_1 = scans[scan1][beac1_1] - pointTransform(scans[scan2][beac2_1], orient);
            if (scan2Pos == scan2Pos_1) {
                numMatches++;
                if (numMatches == 12) return true;
            }
        }
    }
    return false;
}

/* Try to see if 2 scanners match. 
   - Randomly pick 2 scans from scanner 1 (matched) and 1 scans from scanner 2 (unmatched). 
   - Assume beacon #1 from scan1 equals beacon #2 from scan2, and calculate scan2's position.
   - Next, calculate scan2's position using beacon #2 from scan1 and all of scan1's beacons to see if anything leads
     to the same calculated scan2 position from before. If so, check if there are 12 matches using function above.
   - Repeat above 2 steps for all possible orientations.
*/
bool tryMatch(int scan1, int scan2) {
    if (matchedScanners[scan2]) // Scanner 1 treated as already matched scanner
        swap(scan1, scan2); 
    for (int randAttempts = 0; randAttempts < 75; randAttempts++) {
        /* I believe that 75 tries is at worst a ~50% success rate if the scanners match, but it gives the best runtime
           out of what I tried. Fewer attempts = less time spent on non-matching scanners, but might take more than 
           one pass for matching scanners. */
        int beac1_1 = unifDist(generator), beac1_2 = unifDist(generator), beac2_1 = unifDist(generator);
        vector<int> scan2Pos_1(3), scan2Pos_2(3);

        for (int orient = 0; orient < 24; orient++) {
            scan2Pos_1 = scans[scan1][beac1_1] - pointTransform(scans[scan2][beac2_1], orient);
            
            for (unsigned beac2_2 = 0; beac2_2 < scans[0].size(); beac2_2++) {
                scan2Pos_2 = scans[scan1][beac1_2] - pointTransform(scans[scan2][beac2_2], orient);

                if (scan2Pos_1 == scan2Pos_2) { // Potential Scanner Match
                    if (tryScannerLoc(scan2Pos_1, scan1, scan2, orient)) {
                        scannerLocs[scan2] = scan2Pos_1;
                        matchedScanners[scan2] = true;
                        // Change old scan locations to correct coordinates
                        for (unsigned beac2_new = 0; beac2_new < scans[scan2].size(); beac2_new++) 
                            scans[scan2][beac2_new] = scannerLocs[scan2] + pointTransform(scans[scan2][beac2_new], orient);
                        cout << "Matched " << scan1 << " " << scan2 << endl;
                        return true;
                    }
                }
            }
        }
    }
    return false;
}

int main() {
    // Input was modified to remove everything besides numbers and pad scanners with less than 26 beacons with a scan of (0,0,0)
    ifstream infile("19in.txt");
    for (int currScanner = 0; currScanner < 27; currScanner++)
        for (int currBeacon = 0; currBeacon < 26; currBeacon++)
            infile >> scans[currScanner][currBeacon][0] >> scans[currScanner][currBeacon][1] >> scans[currScanner][currBeacon][2];
    
    matchedScanners[0] = true; // Start with 0 as matched, find match to it.
    int numMatches = 1;

    while (numMatches != 27) // Loop until everything is matched.
        for (unsigned i = 0; i < matchedScanners.size(); i++)
            for (unsigned j = 0; j < matchedScanners.size() && j != i; j++)
                if (matchedScanners[i] ^ matchedScanners[j]) // Want 1 matched and 1 unmatched
                    if (tryMatch(i, j))
                        numMatches++;

    /* Part 1: Find number of distinct beacons */
    for (unsigned currS = 0; currS < scans.size(); currS++)
        for (unsigned currB = 0; currB < scans[0].size(); currB++)
            if (scans[currS][currB] != scannerLocs[currS])
                // If statement because I padded scanners with less than 26 scans with a scan of (0,0,0)
                beacons.insert(make_tuple(scans[currS][currB][0], scans[currS][currB][1], scans[currS][currB][2]));
    cout << "Part 1: " << beacons.size() << endl;

    /* Part 2: Find max manhattan distance between scanners */
    int maxDist = 0;
    for (unsigned i = 0; i < matchedScanners.size(); i++)
            for (unsigned j = 0; j < matchedScanners.size() && j != i; j++)
                maxDist = max(maxDist, manhatDist(scannerLocs[i], scannerLocs[j]));
    cout << "Part 2: " << maxDist << endl;

    return 0;
}
