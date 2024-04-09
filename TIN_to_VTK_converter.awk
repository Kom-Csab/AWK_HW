BEGIN {
    count = 0
    vert_amount = 0
    tri_amount = 0
    is_vert_proc = 0
    is_tri_proc = 0
    vertices_record_index = 0
    triangles_row_index = 0
    value_error = 0
}

NF == 0 || /#+/ {
    NR--
    next
}

/^TNAM/ {
    title = $2 #Mivel a TNAM nem kötelező
    next
}

/^VERT/ {
    count += 1
    vert_amount = $2
    is_vert_proc = 1
    vertices_record_index = FNR
    if(ARGC > 2 && count > 1){                     #A jobban olvasható output végett, ha több fájlt adunk meg
        print ""
    }

    print "# vtk DataFile Version 3.0"
    print (title != "") ? title : "VTK output"     #Ha van TNAM akkor a megfelelő értéket írja ki, ha nincs akkor egy alapértelmezettet
    title = ""                                     #Több fájl beolvasása esetén, ha a második fájlnak nem lenne TNAM címe, akkor ne az előzőjét írja ki
    print "ASCII"
    print "DATASET UNSTRUCTURED_GRID", "\n"
    print "POINTS", vert_amount, "float"

    #Ha a vert_amount negatív szám vagy nem szám, akkor az adatok kiírása helyett ellenőrzésre szólít fel

    if(vert_amount <= 0 || !(vert_amount ~ /^[0-9]+$/)){
        printf("\n#\tHibas fajl! Kerem ellenorizze a fajl %d. sorat!\n", vertices_record_index)
        value_error == 0 ? value_error = 1 : pass
        error_check = 1
    }else{
        error_check = 0
    }
    next
}

#Első feltétellel leelenőrzöm, hogy a VERT sor bedolgozásra került-e már,
#majd a második feltétellel pedig azt szabom meg, hogy mennyi csúcspontokat tartalmazó sor van.
#Továbbá muszáj egy hibaellenőrző boolean-t is használnom, mivel ha volt hiba a mennyiség feldolgozásakor,
#akkor nem akarom kiíratni a koordinátákat tartalmazó sorokat.

(is_vert_proc && FNR <= vertices_record_index + vert_amount) && error_check == 0{   
    print $1, $2, $3
    next
}

/^TRI/ {
    triangles_row_index = FNR
    tri_amount = $2
    is_tri_proc = 1
    print ""
    print "CELLS", tri_amount, tri_amount*4
    is_vert_proc = 0

    if(tri_amount <= 0 || !(tri_amount ~ /^[0-9]+$/)){
        printf("\n#\tHibas fajl! Kerem ellenorizze a fajl %d. sorat!\n", triangles_row_index)
        value_error == 0 ? value_error = 1 : pass
        error_check = 1
    }else{
        error_check = 0
    }
    next
}

#Ugyanaz a logika, mint a 26. sorban

(is_tri_proc && FNR <= triangles_row_index + tri_amount) && error_check == 0{
    print "3", $1, $2, $3
    next
}

#Az UNSTRUCTURED_GRID DATASET-ben az ismereteim szerint a fájl végén fel van tüntetve,
#hogy mennyi cella reprezentálja a háromszögeket.
#Az "5" érték a VTK-ban azonosítja a háromszöget

is_tri_proc && error_check == 0{
    print ""
    print "CELL_TYPES", tri_amount
    for(i=1; i<=tri_amount; i++){
        print "5"
    }
    is_tri_proc = 0
    next
}

END {
    if(value_error == 1){
        printf("\n#\tA fajl(ok) feldolgozasa soran hiba lepett fel. Kerem ellenorizze a fajlok tartalmat, majd probalja ujra a konverziot!\n")
    }
}
