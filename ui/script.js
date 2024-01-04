
function display(bool) {
    if (bool) {
        return $("body").show();
    }
    $("body").hide();
}

const menus = ["#characterCreator", "#characterEditor", "#exitGameMenu", "#deleteCharacterMenu", "#spawnLocation"]
function displayMenu(menu, status) {
    if (status) {
        $(`#${menu}`).fadeIn("slow");
        menus.forEach(item => {
            if (!item.includes(menu)) {
                $(item).hide();
            }
        });
        return;
    }
    $(`#${menu}`).fadeOut("slow");
}

function createCharacter(firstName, lastName, dateOfBirth, gender, ethnicity, department, id) {
    const job = department && ` (${department})`
    if (job && (firstName.length + lastName.length + job.length) > 24) {
        $("#charactersSection").append(`<button id="characterButton${id}" class="createdButton animated"><span>${firstName} ${lastName}${job}</span></button><button id="characterButtonEdit${id}" class="createdButtonEdit"><a class="fas fa-edit"></a> Edit</button><button id="characterButtonDelete${id}" class="createdButtonDelete"><a class="fas fa-trash-alt"></a> Delete</button>`);
    } else {
        $("#charactersSection").append(`<button id="characterButton${id}" class="createdButton"><span>${firstName} ${lastName}${job}</span></button><button id="characterButtonEdit${id}" class="createdButtonEdit"><a class="fas fa-edit"></a> Edit</button><button id="characterButtonDelete${id}" class="createdButtonDelete"><a class="fas fa-trash-alt"></a> Delete</button>`);
    }
    $(`#characterButton${id}`).click(function() {
        displayMenu("spawnLocation", true);
        $.post(`https://${GetParentResourceName()}/setMainCharacter`, JSON.stringify({
            id: id
        }));
        return;
    });
    $(`#characterButtonEdit${id}`).click(function() {
        displayMenu("characterEditor", true);
        $("#newFirstName").val(firstName);
        $("#newLastName").val(lastName);
        $("#newDateOfBirth").val(dateOfBirth);
        $("#newGender").val(gender);
        $("#newTwtName").val(ethnicity);
        $("#newDepartment").val(department);
        characterEdited = id
        return;
    });
    $(`#characterButtonDelete${id}`).click(function() {
        displayMenu("deleteCharacterMenu", true);
        characterDeleting = id
        return;
    });
}

$("#characterCreator").submit(function() {
    $.post(`https://${GetParentResourceName()}/newCharacter`, JSON.stringify({
        firstName: $("#firstName").val(),
        lastName: $("#lastName").val(),
        dateOfBirth: $("#dateOfBirth").val(),
        gender: $("#gender").val(),
        ethnicity: $("#twtName").val(),
        department: $("#department").val()
    }));
    displayMenu("characterCreator", false);
    $("#firstName, #lastName, #dateOfBirth, #twtName").val("")
    return false;
});

$("#characterEditor").submit(function() {
    displayMenu("characterEditor", false);
    $.post(`https://${GetParentResourceName()}/editCharacter`, JSON.stringify({
        firstName: $("#newFirstName").val(),
        lastName: $("#newLastName").val(),
        dateOfBirth: $("#newDateOfBirth").val(),
        gender: $("#newGender").val(),
        ethnicity: $("#newTwtName").val(),
        department: $("#newDepartment").val(),
        id: characterEdited
    }));
    return false;
});

$("#deleteCharacterConfirm").click(function() {
    displayMenu("deleteCharacterMenu", false);
    $("#characterButton" + characterDeleting).fadeOut("slow",function(){
        $("#characterButton" + characterDeleting).remove();
    })
    $("#characterButtonEdit" + characterDeleting).fadeOut("slow",function(){
        $("#characterButtonEdit" + characterDeleting).remove();
    })
    $("#characterButtonDelete" + characterDeleting).fadeOut("slow",function(){
        $("#characterButtonDelete" + characterDeleting).remove();
    })
    $.post(`https://${GetParentResourceName()}/delCharacter`, JSON.stringify({
        character: characterDeleting
    }));
    return;
});

$("#newCharacterButton").click(function() {
    displayMenu("characterCreator", true);
    return;
});

$("#deleteCharacterCancel").click(function() {
    displayMenu("deleteCharacterMenu", false);
    return;
});
$("#cancelCharacterCreation").click(function() {
    displayMenu("characterCreator", false);
    return;
});
$("#cancelCharacterEditing").click(function() {
    displayMenu("characterEditor", false);
    return;
});

$("#tpCancel").click(function() {
    displayMenu("spawnLocation", false);
    setTimeout(function(){
        $("#spawnMenuContainer").empty();
    }, 550);
    return;
});

$("#quitGameButton").click(function() {
    displayMenu("exitGameMenu", true);
    return;
});
$("#exitGameCancel").click(function() {
    displayMenu("exitGameMenu", false);
    return;
});
$("#exitGameConfirm").click(function() {
    $.post(`https://${GetParentResourceName()}/exitGame`);
    return;
});

$(document).on("click", ".spawnButtons", function() {
    const th = $(this)
    $.post(`https://${GetParentResourceName()}/tpToLocation`, JSON.stringify({
        x: th.data("x"),
        y: th.data("y"),
        z: th.data("z"),
        id: th.data("id")
    }));
    displayMenu("spawnLocation", false);
    setTimeout(function(){
        $("#spawnMenuContainer").empty();
    }, 550);
    return;
});
$(document).on("click", "#tpDoNot", function() {
    $.post(`https://${GetParentResourceName()}/tpDoNot`, JSON.stringify({
        id: $("#tpDoNot").data("id")
    }));
    displayMenu("spawnLocation", false);
    setTimeout(function(){
        $("#spawnMenuContainer").empty();
    }, 550);
    return;
});

window.addEventListener("message", function(event) {
    const item = event.data;

    if (item.type === "ui") {
        if (item.status) {
            $("#serverName").text(item.serverName);
            $("body").css("background-image", `url(${item.background})`);
            $("#playerAmount").text(item.characterAmount);
            display(true);
        } else {
            display(false);
        }
    }

    if (item.type === "setSpawns") {
        $("#spawnMenuContainer").empty();
        setTimeout(function(){
            $("#tpDoNot").data("id", item.id);
            JSON.parse(item.spawns).forEach((location) => {
                $("#spawnMenuContainer").append(`<button class="spawnButtons" data-x="${location.coords.x}" data-y="${location.coords.y}" data-z="${location.coords.z}" data-id="${item.id}">${location.label}</button>`);
            });
        }, 10);
    }

    if (item.type === "firstSpawn") {
        $("#tpDoNot").html(`<a class="fas fa-compass" style="color:white;"></a> Do not teleport`)
    }

    if (item.type === "givePerms") {
        $(".departments").empty();
        JSON.parse(item.deptRoles).forEach((job) => {
            $(".departments").append(`<option value="${job.name}">${job.label}</option>`);
        });
    }

    if (item.type === "aop") {
        $("#aop").text(`AOP: ${item.aop}`);
    }

    if (item.type === "refresh") {
        $("#charactersSection").empty();
        displayMenu("characterCreator", false);
        let characters = JSON.parse(item.characters)
        Object.keys(characters).forEach((id) => {
            const char = characters[id]
            if (char) {
                createCharacter(
                    char.firstname || "",
                    char.lastname || "",
                    char.dob || "",
                    char.gender || "",
                    char.metadata.ethnicity || "",
                    char.jobInfo?.label || char.job || "",
                    char.id || "",
                );
            }
        });
        if (item.characterAmount) {
            $("#playerAmount").text(item.characterAmount);
        }
    }

    if (item.type === "logo" && item.logo) {
        $("#logo").attr("src", item.logo);
    }
})
