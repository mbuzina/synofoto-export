select
    username,
    folder,
    filename,
    Country,
    StateProvince,
    City,
    Sublocation,
    tags,
    album,
    filename_live,
    takentime,
    rating,
    person as "RegionName",
    x as "RegionAreaX",
    y as "RegionAreaY",
    w as "RegionAreaW",
    h as "RegionAreaH",
    substring(repeat('face, ',numFaces::int),1,numFaces::int*6-2) as "RegionType",
    substring(repeat('normalized, ',numFaces::int),1,numFaces::int*12-2) as "RegionAreaUnit"
from (
    select     
            us.name as username,
            f.name as folder,
            u.filename as filename,
            gc.CountryName Country,
            gc.StateProvince, 
            gc.City, 
            gc.Sublocation,
            array_to_string(array_agg(distinct t.tag),', ') as tags,
            array_to_string(array_agg(distinct a.album),', ') as album,
            (select l_u.filename
             from live_additional l_la
             inner join unit l_u on l_la.id_unit = l_u.id
             where l_la.grouping_key = la.grouping_key and l_u.type = 1
             limit 1) filename_live,
            to_timestamp(u.takentime) at time zone 'gmt' takentime,
            md.rating,
            face.person,
            face.x,
            face.y,
            face.w,
            face.h,
            face.numFaces
    from user_info us 
            inner join unit u on us.id = u.id_user
            inner join folder f on u.id_folder = f.id and f.id_user = us.id
            inner join metadata md on md.id_unit = u.id
            left outer join live_additional la on u.id = la.id_unit
            inner join (select 
                    g.id id,
                    gi.Country as CountryName,
                    case when coalesce(split_part(g.grouping_key,'$',2),'') <> '' then split_part(g.grouping_key,'$',2) else split_part(g.grouping_key,'$',3) end StateProvince,
                    case 
                        when gi.Country=split_part(g.grouping_key,'$',1) or (coalesce(gi.first_level,'') = '')  then 
                            case 
                                when coalesce(split_part(g.grouping_key,'$',5),'') <> '' and coalesce(split_part(g.grouping_key,'$',5),'')<>coalesce(split_part(g.grouping_key,'$',6),'') and coalesce(split_part(g.grouping_key,'$',6),'') <> '' then split_part(g.grouping_key,'$',5)
                                when coalesce(split_part(g.grouping_key,'$',4),'') <> '' then split_part(g.grouping_key,'$',4)
                                else split_part(g.grouping_key,'$',3)
                            end
                        else gi.first_level
                    end City,
                    case
                        when gi.Country=split_part(g.grouping_key,'$',1) or (coalesce(gi.second_level,'') = '')  then 
                            case 
                                when coalesce(split_part(g.grouping_key,'$',6),'') = '' and 
                                    case 
                                        when gi.Country=split_part(g.grouping_key,'$',1) or (coalesce(gi.first_level,'') = '')  then 
                                            case 
                                                when coalesce(split_part(g.grouping_key,'$',5),'') <> '' and coalesce(split_part(g.grouping_key,'$',5),'')<>coalesce(split_part(g.grouping_key,'$',6),'') and coalesce(split_part(g.grouping_key,'$',6),'') <> '' then split_part(g.grouping_key,'$',5)
                                                when coalesce(split_part(g.grouping_key,'$',4),'') <> '' then split_part(g.grouping_key,'$',4)
                                                else split_part(g.grouping_key,'$',3)
                                            end
                                        else gi.first_level
                                    end <> coalesce(split_part(g.grouping_key,'$',5),'') 
                                    then split_part(g.grouping_key,'$',5)
                                else split_part(g.grouping_key,'$',6)
                            end
                        else gi.second_level
                    end Sublocation,
                    g.grouping_key 
                from geocoding_info gi inner join geocoding g on gi.id_geocoding = g.id 
                where gi.lang=7) gc on u.id_geocoding = gc.id
            left outer join (select m.id_unit, g.id_user, g.name as tag from many_unit_has_many_general_tag m inner join general_tag g on m.id_general_tag = g.id) t on u.id = t.id_unit and us.id = t.id_user
            left outer join (select m.id_item, a.name as album from many_item_has_many_normal_album m inner join album a on m.id_normal_album = a.id) a on u.id = a.id_item
            left outer join (
                select fa.id_unit, p.id_user,
                    array_to_string(array_agg(p.name),', ') person,
                    array_to_string(array_agg((json_extract_path_text(bounding_box,'top_left','x')::float + json_extract_path_text(bounding_box,'bottom_right','x')::float) / 2),', ') as x,
                    array_to_string(array_agg((json_extract_path_text(bounding_box,'top_left','y')::float + json_extract_path_text(bounding_box,'bottom_right','y')::float) / 2),', ') as y,
                    array_to_string(array_agg(json_extract_path_text(bounding_box,'bottom_right','x')::float - json_extract_path_text(bounding_box,'top_left','x')::float),', ') as w,
                    array_to_string(array_agg(json_extract_path_text(bounding_box,'bottom_right','y')::float - json_extract_path_text(bounding_box,'top_left','y')::float),', ') as h,
                    count(*) as numFaces,
                    array_agg(p.name || ' | ' || fa.id_person || ' | ' || fa.id_person_group || ' | ' || fa.bounding_box) as faces 
                from 
                    face fa 
                    inner join person p on fa.id_person = p.id
                where 
                    name is not null
                group by
                    fa.id_unit, p.id_user) face on u.id = face.id_unit and us.id = face.id_user
        where f.name='/Urlaube/2022_02 Snowboard Ladis mit Dirk'
        group by
            username,
            folder,
            filename,
            gc.CountryName,
            gc.StateProvince,
            gc.City, 
            gc.Sublocation,
            face.person,
            face.x, 
            face.y, 
            face.w, 
            face.h, 
            face.numFaces, 
            la.grouping_key,
            takentime,
            rating) a;
