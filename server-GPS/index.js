const express = require('express')
const mysql = require('mysql2/promise');
const bodyParser = require('body-parser');

const db_info = {host: 'localhost',
user: 'ian',
password: 'password',
database: 'project'
};

async function add_user(body) {
    let results = await query(`INSERT INTO Users(username) VALUES('${body.data.username}')`);
    return results[0];
}

async function add_monitor_user(body) {
    let results = await query(`INSERT INTO Monitor_Users(username) VALUES('${body.data.username}')`);
    return results[0];
}

async function update_incidents(body) {
    let owner_id = await get_user_id(body.data.username);
    let results = await query(`INSERT INTO Incidents (owner_id, lat, lon, speed, speed_limit, username, kind) 
                                VALUES (${owner_id}, ${body.data.latitude}, ${body.data.longitude}, ${body.data.speed}, ${body.data.speed_limit},"${body.data.username}", "${body.data.type}")`);
    return results[0];
}

async function add_monitor(body) {
    let user_id = await get_user_id(body.data.username);
    let monitor_id = await get_monitor_id(body.data.monitor_user);
    let results = await query(`INSERT INTO User_Map (owner_id, watch_id) 
                                VALUES (${monitor_id}, ${user_id})`);
    console.log(results[0])
    return results[0];
}

async function get_incidents(monitor_username) {
    // query db
    let monitor_id = await get_monitor_id(monitor_username);
    let results = await query(`SELECT watch_id FROM User_Map WHERE owner_id = '${monitor_id}'`);
    let watch_id_list = results[0];
    let response_list = []
    for (var i = 0; i < watch_id_list.length; i++) {
        let results1 = await query(`SELECT id, lat, lon, speed, owner_id, username, speed_limit, kind FROM Incidents WHERE owner_id=${watch_id_list[i].watch_id}`);
        response_list = response_list.concat(results1[0]);
    }
    console.log(response_list);
    return response_list
}

async function get_monitors(username) {
    let watch_id = await get_user_id(username);
    let results = await query(`SELECT owner_id FROM User_Map WHERE watch_id=${watch_id}`);
    let id_list = results[0];
    let response_arr = [];
    for (var i = 0; i < id_list.length; i++) {
        response_arr[i] = {"username": await get_monitor_username(id_list[i].owner_id)};
    }
    console.log(response_arr)
    return response_arr;
}

async function del_monitor(body) {
    let watch_id = await get_user_id(body.data.username);
    let owner_id = await get_monitor_id(body.data.monitor_user);
    let results = await query(`DELETE FROM User_Map WHERE watch_id=${watch_id} AND owner_id=${owner_id}`);
    return results[0];
} 


async function get_user_id(username) {
    let results = await query(`SELECT id FROM Users WHERE username='${username}'`)
    return results[0][0].id
}

async function get_monitor_id(monitor_username) {
    let results = await query(`SELECT id FROM Monitor_Users WHERE username='${monitor_username}'`)
    return results[0][0].id
}

async function get_monitor_username(monitor_id) {
    let results = await query(`SELECT username FROM Monitor_Users WHERE id=${monitor_id}`)
    return results[0][0].username;
}

// Query DB
async function query(sql) {
    const connection = await mysql.createConnection(db_info);
    let results = await connection.execute(sql);
    connection.end(function(err) {
        if (err) {return console.log('error:' + err.message);}
        console.log('Close the database connection.');
    });
    return results;
}

const app = express()
const port = 3000

app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

app.get('/', (req, res) => res.send('Index'))

// Adding users
app.post('/add_user', async function(req, res) {
    try {
        res.json(await add_user(req.body));
    } catch (err) {
        console.error("error: ", err.message);
    }
});

app.post('/add_monitor_user', async function(req, res) {
    try {
        res.json(await add_monitor_user(req.body));
    } catch (err) {
        console.error("error: ", err.message);
    }
});

// Changing User_Map
app.post('/add_monitor', async function(req, res) {
    try {
        res.json(await add_monitor(req.body));
    } catch (err) {
        console.error("error: ", err.message);
    }
});

// Adding incidents
app.post('/update', async function (req, res) {
    try {
        res.json(await update_incidents(req.body));
    } catch (err) {
        console.error("error: ", err.message);
    }
});

// Get list of incidents
app.get('/incidents', async function (req, res) {
    try {
        res.json(await get_incidents(req.query.monitor_username));
    } catch (err) {
        console.error("error: ", err.message);
    }
});
 
// Get Monitors
app.get('/monitors', async function (req, res) {
    console.log("GET MONITORS");
    try {
        res.json(await get_monitors(req.query.username));
    } catch (err) {
        console.error("error: ", err.message);
    }
});

// Get Monitors
app.put('/monitors', async function (req, res) {
    try {
        res.json(await del_monitor(req.body));
    } catch (err) {
        console.error("error: ", err.message);
    }
});



app.listen(
    port,
    () => console.log('listening...')
)
