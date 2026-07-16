.pragma library

// Returns a list of connections and nodes
/*
{
    "places": [1,2,3],
    "connections": [1,2]
}
*/
function bidirectionalAStar(worldMap, startId, goalId) {
    // 1. Index places by ID for O(1) lookups
    let places = {};
    worldMap.places.forEach(p => {
        places[p.id] = p;
    });

    if (!places[startId] || !places[goalId]) return {"places":[],"connections": []};
    if (startId === goalId) return {"places": [startId],"connections": []};

    // 2. Build adjacency list from connections (treating it as bidirectional graph)
    let adjacency = {};
    let connectionMap = {};

    worldMap.places.forEach(p => { adjacency[p.id] = []; });

    worldMap.connections.forEach(conn => {
        if (adjacency[conn.from] !== undefined && adjacency[conn.to] !== undefined) {
            adjacency[conn.from].push(conn.to);
            adjacency[conn.to].push(conn.from); // Assuming undirected graph

            // Store both directions since the graph is bidirectional
            connectionMap[conn.from + "-" + conn.to] = conn.id;
            connectionMap[conn.to + "-" + conn.from] = conn.id
        }
    });

    // Helper: Euclidean distance
    function distance(id1, id2) {
        const p1 = places[id1];
        const p2 = places[id2];
        return Math.sqrt(Math.pow(p1.x - p2.x, 2) + Math.pow(p1.y - p2.y, 2));
    }

    // 3. Initialize Forward and Backward Search Structures
    // Tracks g-scores (shortest known distance from start/goal)
    let gF = { [startId]: 0 };
    let gB = { [goalId]: 0 };

    // Track parent pointers to reconstruct paths
    let parentF = { [startId]: null };
    let parentB = { [goalId]: null };

    // Open sets (using simple arrays for tracking; sorted on extraction)
    let openF = [startId];
    let openB = [goalId];

    // Closed sets to keep track of fully expanded nodes
    let closedF = new Set();
    let closedB = new Set();

    // Track the best complete path found so far
    let mu = Infinity;
    let intersectionNode = null;

    // 4. Main Search Loop
    while (openF.length > 0 && openB.length > 0) {
        // Condition to terminate: Best path found is shorter than any potential paths ahead
        if (openF.length > 0 && openB.length > 0) {
            // Find minimum f-values in current frontiers
            const minF = Math.min(...openF.map(id => gF[id] + distance(id, goalId)));
            const minB = Math.min(...openB.map(id => gB[id] + distance(id, startId)));
            if (mu <= Math.max(minF, minB)) {
                break;
            }
        }

        // Balance expansion: Choose the side with the smaller frontier
        if (openF.length <= openB.length) {
            // --- Forward Expansion ---
            openF.sort((a, b) => (gF[a] + distance(a, goalId)) - (gF[b] + distance(b, goalId)));
            const currF = openF.shift();
            closedF.add(currF);

            for (const neighbor of adjacency[currF]) {
                if (closedF.has(neighbor)) continue;

                const tentativeG = gF[currF] + distance(currF, neighbor);
                if (gF[neighbor] === undefined || tentativeG < gF[neighbor]) {
                    gF[neighbor] = tentativeG;
                    parentF[neighbor] = currF;
                    if (!openF.includes(neighbor)) openF.push(neighbor);

                    // If this node has also been visited by the backward search, update mu
                    if (gB[neighbor] !== undefined) {
                        const totalDist = tentativeG + gB[neighbor];
                        if (totalDist < mu) {
                            mu = totalDist;
                            intersectionNode = neighbor;
                        }
                    }
                }
            }
        } else {
            // --- Backward Expansion ---
            openB.sort((a, b) => (gB[a] + distance(a, startId)) - (gB[b] + distance(b, startId)));
            const currB = openB.shift();
            closedB.add(currB);

            for (const neighbor of adjacency[currB]) {
                if (closedB.has(neighbor)) continue;

                const tentativeG = gB[currB] + distance(currB, neighbor);
                if (gB[neighbor] === undefined || tentativeG < gB[neighbor]) {
                    gB[neighbor] = tentativeG;
                    parentB[neighbor] = currB;
                    if (!openB.includes(neighbor)) openB.push(neighbor);

                    // If this node has also been visited by forward search, update mu
                    if (gF[neighbor] !== undefined) {
                        const totalDist = tentativeG + gF[neighbor];
                        if (totalDist < mu) {
                          mu = totalDist;
                          intersectionNode = neighbor;
                        }
                    }
                }
            }
        }
    }

    // 5. Reconstruct Path if an intersection was found
    if (intersectionNode === null) return {"places":[],"connections": []}; // No path found

    let path = [];

    // Trace back forward path (Start -> Intersection)
    let curr = intersectionNode;
    while (curr !== null) {
        path.unshift(curr);
        curr = parentF[curr];
    }

    // Trace forward backward path (Intersection -> Goal)
    curr = parentB[intersectionNode];
    while (curr !== null) {
        path.push(curr);
        curr = parentB[curr];
    }

    // Convert place path into connection path
    let connectionPath = [];

    for (let i = 0; i < path.length - 1; i++) {
        const key = path[i] + "-" + path[i + 1];

        if (connectionMap[key] !== undefined)
            connectionPath.push(connectionMap[key]);
    }

    return {"places": path,"connections": connectionPath};
}