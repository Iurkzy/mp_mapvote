#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

init()
{
    level thread onPlayerConnecting();

    game["menu_mapvote"] = "mapvote";
    precacheMenu(game["menu_mapvote"]);

    setDvar("voting_time", 30);
    setDvar("scr_intermission_time", 0);

    level.t5maps = "mp_array,mp_cracked,mp_crisis,mp_firingrange,mp_duga,mp_hanoi,mp_cairo,mp_havoc,mp_cosmodrome,mp_nuked,mp_radiation,mp_mountain,mp_villa,mp_russianbase,mp_berlinwall2,mp_discovery,mp_kowloon,mp_stadium,mp_gridlock,mp_hotel,mp_outskirts,mp_zoo,mp_drivein,mp_area51,mp_golfcourse,mp_silo";
    
    setDvar("ui_vote_1_count", 0);
    setDvar("ui_vote_2_count", 0);
    setDvar("ui_vote_3_count", 0);
    setDvar("ui_vote_4_count", 0);

    if( getDvar("ui_mapFocus") != "" )
        setDvar("ui_mapFocus", "");
}

onPlayerConnecting()
{
    level endon("game_ended");
    for(;;)
    {
        level waittill("connecting", player);
        player thread onPlayerSpawned();

        player thread CustomMenuResponse();

        wait .1;
    }
}

onPlayerSpawned()
{
    for(;;)
    {
        self waittill("spawned_player");
        
        wait .1;
    }
}

CustomMenuResponse()
{
    self endon("disconnect");
    for(;;)
    {
        self waittill("menuresponse", menu, response);

        if( menu == game["menu_mapvote"] )
        {
            switch( response )
            {
                case "vote_1": self voteForMap(1); break;
                case "vote_2": self voteForMap(2); break;
                case "vote_3": self voteForMap(3); break;
                case "vote_4": self voteForMap(4); break;
            }
        }

        wait .1;
    }
}

updateGameTimer()
{
	level endon ( "stop_votetime" );
	while( 1 )
	{
        setDvar("voting_time", getDvarInt("voting_time") - 1);
		wait ( 1.0 );
	}
}

initiate_mapvote()
{
    setDvar( "ui_vote_1", getRandomMap() );
    setDvar( "ui_vote_2", getRandomMap() );
    setDvar( "ui_vote_3", getRandomMap() );

    self closeMenu();
    self closeInGameMenu();

    self [[level.spectator]]();

    self openMenu( game["menu_mapvote"] );
    setDvar("vote_in_process", true);

    level.isVoting = true;
    level thread updateGameTimer();

    wait 30;

    setDvar("vote_in_process", false);

    level.isVoting = false;
    level notify("stop_votetime");

    setDvar("voting_time", 10);

    level thread updateGameTimer();

    setDvar( "vote_winner", getHighestVote() );
    setDvar( "sv_maprotation", getDvar("vote_winner") );

    wait 10;
    level notify("stop_votetime");
	
	map( getDvar("vote_winner"), false );
    // exitLevel( false );
}

getRandomMap()
{
    map = strTok( level.t5maps, "," );
    random = randomintrange(0, map.size - 1);

    if( map[random] != getDvar("ui_mapname") 
     && map[random] != getDvar("ui_vote_1") 
     && map[random] != getDvar("ui_vote_2") 
     && map[random] != getDvar("ui_vote_3"))
        return map[random];
}

voteForMap( map )
{
    if(!isDefined( self.hasVoted ) || !self.hasVoted)
    {
        self.hasVoted = true;
        self.currentVote = map;

        setDvar("ui_vote_" + map + "_count", getDvarInt("ui_vote_" + map + "_count") + 1);
    }
    else if( isDefined(self.hasVoted) && self.hasVoted && map != self.currentVote )
    {
        setDvar("ui_vote_" + self.currentVote + "_count", getDvarInt("ui_vote_" + self.currentVote + "_count") - 1);

        self.currentVote = map;
        setDvar("ui_vote_" + map + "_count", getDvarInt("ui_vote_" + map + "_count") + 1);
    }
}

getHighestVote() // not even sure if this logic works, could probably be cleaner
{
    if( !getDvar("vote_in_process") )
    {
        for(i = 1; i < 4; i++)
        {
            if( getDvarInt("ui_vote_1_count") > getDvarInt("ui_vote_" + i + "_count") && i != 1 )
                return getDvar("ui_vote_1");

            else if( getDvarInt("ui_vote_2_count") > getDvarInt("ui_vote_" + i + "_count") && i != 2 )
                return getDvar("ui_vote_2");

            else if( getDvarInt("ui_vote_3_count") > getDvarInt("ui_vote_" + i + "_count") && i != 3 )
                return getDvar("ui_vote_3");

            else if( getDvarInt("ui_vote_4_count") > getDvarInt("ui_vote_" + i + "_count") && i != 4 )
                return getDvar("ui_vote_4");

            else if( getDvarInt("ui_vote_1_count") == getDvarInt("ui_vote_" + i + "_count") && i > 1 )
                return getDvar("ui_vote_1");

            else if( getDvarInt("ui_vote_2_count") == getDvarInt("ui_vote_" + i + "_count") && i > 2 )
                return getDvar("ui_vote_2");

            else if( getDvarInt("ui_vote_1_count") == getDvarInt("ui_vote_" + i + "_count") && i > 3 )
                return getDvar("ui_vote_3");

            else if( getDvarInt("ui_vote_4_count") == getDvarInt("ui_vote_" + i + "_count") && i > 4 )
                return getDvar("ui_vote_4");
            
            else // default to the first option if no one votes
                return getDvar("ui_vote_1");
        }
    }
}