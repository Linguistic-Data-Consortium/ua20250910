<script>
    import { Toaster } from "$lib/components/ui/sonner";
    import * as Tabs from "$lib/components/ui/tabs";
    import * as Tooltip from "$lib/components/ui/tooltip";
    import * as Dialog from "$lib/components/ui/dialog";
    import { Label } from "$lib/components/ui/label";
    import { Input } from "$lib/components/ui/input";
    import { Button, buttonVariants } from "$lib/components/ui/button";
    import { btn, cbtn, dbtn } from '../lib/ldcjs/work/buttons';
    import { getp } from '../lib/ldcjs/getp';
    import Help from './help.svelte';
    import Spinner from '../lib/ldcjs/work/spinner.svelte';
    import Table from '../lib/ldcjs/work/table.svelte';
    import Patch from './patch.svelte';
    import InputText from './input_text.svelte';
    import InputSelect from './input_select.svelte';
    import InputCheckbox from './input_checkbox.svelte';
    import {
        controller_actions,
        get_kits_for_task,
        get_kits_for_task_all,
        reassign_kits_for_task,
        show_kit,
        create_kits_from_kits_tab
    } from './controllers';
    import { toast } from "svelte-sonner";
    import { response, ok_reload } from './helpers';
    import { tick } from 'svelte';
    let { admin = false, portal_manager = false, project_manager = false } = $props();
    let lead_annotator = $state(project_manager);
    let help = $state(false);
    // let page = 1;
    // function pagef(e){ page = e.detail }
    // let pages = [
    //     [ 'Work',        'all',            "your tasks with links to start" ],
    //     [ 'Projects',    'all',            'projects, tasks, kits' ],
    //     [ 'Browse',      'all',            'browse uploaded files' ],
    //     [ 'Kit Types',   'lead_annotator', 'tasks require a kit type' ],
    //     [ 'Namespaces',  'lead_annotator', 'kit types require a namespace' ],
    //     [ 'Tools',       'lead_annotator', 'kit types require a namespace' ],
    //     [ 'Data Sets',   'lead_annotator', 'tasks can have a data set' ],
    //     [ 'Invites',     'lead_annotator', 'invite people to the site' ],
    //     [ 'Scripts',     'lead_annotator', 'write scripts' ],
    //     [ 'Features',    'admin',          'features for different objects' ],
    //     [ 'Services',    'admin',          'services' ],
    //     [ 'Workflows',   'admin',          'workflows' ],
    //     [ 'Groups',      'admin',          'groups' ],
    //     [ 'Permissions', 'all',            'explore roles and permissions' ]
    // ];
    // let goto_project = $state();
    function goto(x, y){
        if(x.task_id){
            tab = 'projects';
            if(y == 'project') project(x);
            if(y == 'task') task(x);
        }
    }
    function project(e){
        actions.project.get_all();
        all_label = (lead_annotator ? "All" : "My") + " Projects";
        if(e){
            models.project.id = e.project_id;
            models.task.id = null;
            actions.project.get_one('tasks');
        }
    }
    // let goto_task = $state();
    function task(e){
        project(e);
        models.task.id = e.task_id;
        actions.task.get_one('kits');
    }
    // document.getElementById('work1').hidden = true;
    function helpf(e){
        alert(e.detail);
    }
    
    export function browse(x){
        tab = 'browse';
        // browse_a.step1(x);
    }
    let browsex = $state();
    export function uploads(e){
        // page5();
        // browsex.get(e);
    }
    let p = getp(window.location);
    console.log('USERS');
    p.then( (x) => console.log(x) )
    let tab = $state('tasks');
    let tabp = $state(Promise.resolve([]));
    let pp = $state();
    let taskpp = $state();
    let taskuserpp = $state();
    let kitsp = $state();
    let kitspp = $state();
    let donekitsp = $state();
    let style = $state();
    let style_timeout;
    function set_style(e){
        style = `position: absolute; left: ${e.pageX-20}px; top: ${e.pageY+20}px; z-index: 10`;
        if(style_timeout) clearTimeout(style_timeout);
        style_timeout = setTimeout( () => style = null, 2000);
    };
    let member_timeout;
    let memberp = $state(Promise.resolve([]));
    let member_name = $state();
    function memberf(name){
        if(models.task.tab == 'members'){
            return pp.then(x => x.members);
        }
        else if(models.project.tab == 'members'){
            return controller_actions.project_user.not_in(models.project.id, name);
        }
        else if(models.group.tab == 'members'){
            return controller_actions.group_user.not_in(models.group.id, name);
        }
    }
    // use a named function so effect only binds to member_name
    $effect(() => check_member_name(member_name));
    function check_member_name(name){
        if(!name || name.length < 3){
            memberp = Promise.resolve([]);
            return;
        }
        if(typeof(memberf) == 'object'){
            memberp = Promise.resolve(memberf);
            return;
        }
        if(member_timeout) clearTimeout(member_timeout);
        member_timeout = setTimeout(() => memberp = memberf(name), 500);
    }
    function create_name(){
        return { name: document.getElementById('dialog_create_name').value };
    }
    function create_category(){
        return { category: document.getElementById('dialog_create_category').value };
    }
    function member_create(model, x){
        let o = { user_id: x.id };
        if(model == 'task') o.user_id = x.user_id;
        o[model + '_id'] = models[model].id;
        controller_actions[model + '_user'].create(o)
        .then(x => ok_reload(x, () => actions[model].get_one('members')))
        .then(member_name = null);
    }
    function member_delete(model){
        controller_actions[model + '_user'].delete(models[model].user_id)
        .then(x => ok_reload(x, () => actions[model].get_one('members')))
        .then(models[model].user_id = null);
    }
    function selectedfmember(model, x){
        models[model].user_id = x;
        if(model == 'task') taskuserpp = x && controller_actions.task_user.get_one(x);
    }
    let all_label = $state();
    function tabs(tab){
        pp = null;
        taskpp = null;
        switch(tab){
            case 'projects':
                project();
                break;
            case 'kit_types':
                actions.kit_type.get_all();
                all_label = "All Kit Types";
                break;
            case 'features':
                actions.feature.get_all();
                all_label = "All Features";
                break;
            case 'workflows':
                actions.workflow.get_all();
                all_label = "All Workflows";
                break;
            case 'groups':
                actions.group.get_all();
                all_label = "All Groups";
                break;
            case 'invites':
                actions.invite.get_all();
                all_label = "All Invites";
                break;
        }
    }


    const models = $state({
        kit_type: {
            label: 'Kit Type',
            desc: 'A Kit Type holds parameters for kit behavior.',
            id: null,
            index: null
        },
        kit: {
            label: 'Kit',
            desc: 'A Kit is a unit of work.',
            id: null,
            index: null
        },
        donekit: {
            label: 'Done Kit',
            desc: 'A Kit is a unit of work.',
            id: null,
            index: null
        },
        project: {
            label: 'Project',
            desc: 'A Project is a set of Tasks and a set of Users.',
            id: null,
            index: null,
            tab: 'info',
            user_id: null,
            user_index: null
        },
        task: {
            label: 'Task',
            desc: 'A Task is a set of Kits and a set of Users.',
            id: null,
            index: null,
            tab: 'info',
            user_id: null,
            user_index: null
        },
        feature: {
            label: 'Feature',
            desc: 'A Feature is an attribute of an object.',
            id: null,
            index: null
        },
        workflow: {
            label: 'Workflow',
            desc: 'A Workflow controls kit assignment.',
            id: null,
            index: null
        },
        group: {
            label: 'Group',
            desc: 'A Group is a set of Users.',
            id: null,
            index: null,
            tab: 'info',
            user_id: null,
            user_index: null
        },
        invite: {
            label: 'Invite',
            desc: 'An invitation for a new user.',
            id: null,
            index: null
        }
    });
    const actions = $derived.by(() => {
        const model_actions = {};
        for(let x in controller_actions){
            model_actions[x] = {};
            model_actions[x].get_all = () => {
                tabp = controller_actions[x].get_all();
                models[x].id = null;
            };
            model_actions[x].get_one = () => pp = controller_actions[x].get_one(models[x].id);
            model_actions[x].create = () => controller_actions[x].create(create_name()).then(y => response(y, model_actions[x].get_all));
            model_actions[x].delete = () => controller_actions[x].delete(models[x].id).then(y => response(y, model_actions[x].get_all, () => models[x].id = null));
            model_actions[x].patch = (y) => controller_actions[x].patch(models[x].id, y);
        }
        // overrides
        model_actions.project.get_one = (x) => {
            pp = controller_actions.project.get_one(models.project.id);
            taskpp = null;
            models.project.user_id = null;
            models.project.tab = x || 'info';
            // memberf = (name) => controller_actions.project_user.not_in(models.project.id, name);
        };
        model_actions.project_user.patch = (x) => controller_actions.project_user.patch(models.project.user_id, x);
        model_actions.task.get_one = (x) => {
            console.log(x)
            taskpp = controller_actions.task.get_one(models.project.id, models.task.id)
            .then(x => {
                x.statuses = [ 'active', 'inactive' ];
                x.workflow = null;
                x.workflows_menu = [];
                for(let y of x.workflows){
                    if(
                        (
                            y.name != 'Bucket' &&
                            y.name != 'BucketUser' &&
                            y.name != 'SecondPass'
                        )
                        ||
                        y.id == x.workflow_id
                    ){
                        x.workflows_menu.push(y);
                    }
                    if(y.id == x.workflow_id){
                        x.workflow = y;
                        // break;
                    }
                }
                for(let y of x.kit_types){
                    if(y.id == x.kit_type_id){
                        x.kit_type = y;
                        break;
                    }
                }
                x.data_sets = [ { id: null, name: 'none'} ].concat(x.data_sets);
                for(let y of x.data_sets){
                    if(y.id == x.data_set_id){
                        x.data_set = y;
                        break;
                    }
                }
                x.menu_tasks = [ { id: 0, name: 'none'} ].concat(x.tasks);
                if(x.meta['1p_task_id']){
                    for(let y of x.tasks){
                        if(y.id == Number(x.meta['1p_task_id'])){
                            x.menu_task = y;
                            break;
                        }
                    }
                }
                else{
                    x.menu_task = x.menu_tasks[0];
                }
                x.constraintb = {};
                for(let y of x.features){
                    if(y.name == y.value) x.constraintb[y.name] = x.meta[y.name] == y.name;
                    else                  x.constraintb[y.name] = x.meta[y.name];
                }
                console.log('taskusers', x)
                // models.task.task_admin_bool = x.task_admin_bool;
                // models.task.members = x.members;
                return x;
            });
            models.task.user_id = null;
            models.task.tab = x || 'info';
            taskuserpp = null;
            kitsp = null;
            donekitsp = null;
            // memberf = (name) => controller_actions.task_user.not_in(models.task.id, name);
        };
        model_actions.task.create = () => {
            controller_actions.task.create(models.project.id, create_name())
            .then(y => response(y, () => model_actions.project.get_one('tasks')));
        };
        model_actions.task.delete = () => {
            controller_actions.task.delete(models.task.id)
            .then(y => response(y, () => model_actions.project.get_one('tasks'), () => models.task.id = null));
        };
        model_actions.task_user.patch = (x) => controller_actions.task_user.patch(models.task.user_id, x);
        model_actions.kit_type.get_one = () => {
            pp = controller_actions.kit_type.get_one(models.kit_type.id)
            .then(x => {
                for(let y of x.node_classes){
                    if(y.id == x.node_class_id){
                        x.node_class = y;
                        break;
                    }
                }
                x.constraintb = {};
                for(let y of x.features){
                    if(y.name == y.value) x.constraintb[y.name] = x.constraints[y.name] == y.name;
                    else                  x.constraintb[y.name] = x.constraints[y.name];
                }
                return x;
            });
        };
        model_actions.feature.create = () => {
            const { category } = create_category();
            const { name } = create_name();
            controller_actions.feature.create({ category, name })
            .then(x => response(x, model_actions.feature.get_all));
        };
        // model_actions.group.get_one = () => {
        //     pp = controller_actions.group.get_one(models.group.id);
        //     .then( x => {
        //         x.group_admin_bool
        //     });
        //     // memberf = (name) => controller_actions.group_user.not_in(models.group.id, name);
        // };
        return model_actions;
    });

    const task_user_states = [ null, 'needs_kit', 'has_kit', 'hold', 'paused' ];

    // let kitsp = $derived( () => models.task.tab == 'kits' ? getp(`/kits/task/${task_id}`));
    $effect( () =>  {
        if(models.task.tab == 'kits'){
            // taskpp.then( (x) => get_kitsp(x.id) );
            // taskpp.then( console.log('there'))
            get_kitsp();
        }
    } );
    $effect( () =>  {
        if(models.task.tab == 'done'){
            get_donekitsp();
        }
    } );
    // export let reload;
    // let name;
    // setInterval( () => {
    //     console.log(models.task.task_admin_bool);
    // }, 1000)
    function get_kitsp(task_id){
        // setTimeout( () => console.log(task_id), 1000);
        // return;
        kitspp = null;
        // console.log(models.task.members)
        kitsp = get_kits_for_task(models.task.id).then( (x) => {
            return x;
        } );
        // donekitsp = kitsp.then(x => x.filter(x => x.state == 'done'));
    }
    function get_donekitsp(task_id){
        kitspp = null;
        // console.log(models.task.members)
        donekitsp = get_kits_for_task(models.task.id).then( (x) => {
            return x;
        } ).then(x => x.filter(x => x.state == 'done'));
    }
    
    function responsex(data){
        let flash_value;
        if(!data){
            toast.error('bad response');
        }
        else if(data.error){
            flash_value = data.error.join(' ');
            toast.error(flash_value);
        }
        else{
            if(data.deleted){
                flash_value = data.deleted;
            }
            else if(data.uids){
                flash_value = `${data.uids.success.length} modified, ${data.uids.error.length} failed`;
                get_kitsp();
            }
            else{
                flash_value = "created " + data.task.name;
            }
            toast.success(flash_value);
            // setTimeout( () => reload() , 1000 );
        }
    }
    function open_kit(){
        kitspp = show_kit(models.kit.id);
    }
    function back(){
        kitspp = null;
    }
    let kits_for_task_table = $state();
    let donekits_for_task_table = $state();
    function reassign(project_id, task_id){
        let uids = [];
        for(let x of kits_for_task_table.get_matched()){
            uids.push(x.uid);
        }
        let o = { uids: uids.join(',') };
        if(!kits_for_task_table.match_attempted()){
            toast.error("you haven't matched any kits");
        }
        else if(new_user || new_state){
            if(new_user){
                o.new_user = new_user.name;
            }
            if(new_state){
                o.new_state = new_state;
            }
            reassign_kits_for_task(project_id, task_id, o).then(responsex);
        }
        else{
            toast.error('neither user nor state specified');
        }
    }
    let new_user = $state();
    let new_state = $state();
    let states = [ 'unassigned', 'assigned', 'done', 'broken', 'excluded', 'priority' ];
    let emptyv = { name: '' };






    const parse_jsonn = (x) => JSON.parse(x);
    let typed = $state();
    let json_typed = $state();
    let files = $state();
    let text_upload = $state();
    let json_upload = $state();
    function parse_kits(text){
        const j = [];
        for(let x of text.split("\n")){
            if(x.length) j.push( { docid: x } );
        }
        return j;
    }
    let tdf = $state(false);
    let jsonn;
    function upload(){
        const r = new FileReader();
        let o = null;
        r.onload = function(e){
            text_upload = e.target.result;
            if(text_upload.match(/^\S+\n/)){
                tdf = true;
            }
        }
        r.readAsText(files[0]);
    }
        // that.w.add_timestamps2 data
        // $('#browse_b').html 'working...'
        // ldc_annotate.add_callback ->
        //     $('.Root').show()
        //     $('#browse_b').hide()
    function add(task_id, json){
        const j = { task_id: task_id, kits: json };
        create_kits_from_kits_tab(j).then( (data) => {
            console.log(data);
            get_kitsp();
        });
    }


    let textt = $state();
    let json_download = $state(false);
    let include_headers = $state(false);
    let filename = $state();
    let link = $state();
    let url = $state();
    let downloadp = $state(Promise.resolve({}));
    function create_download(task_id){
        downloadp = get_kits_for_task_all(task_id).then( (data) => {
            const t = [];
            const zip = new JSZip();
            const folder = zip.folder('transcripts');
            let text;
            for(let kit of data){
                for(let s of kit.segments){
                    s.section = { name: s.section };
                }
                let text = create_transcript(kit.kit_uid, include_speaker, include_section, include_headers, kit.segments);
                if(!textt) textt = text;
                folder.file(`${kit.kit_uid}.tsv`, text);
            }
            zip.generateAsync({type: 'blob'}).then( (blob) => {
                url = URL.createObjectURL(blob);
                tick().then( () => link.href = url );
            })
        });
    }
    let include_speaker = $state(false);
    let include_section = $state(false);


    const user_none = { user_id: 0, name: 'none'};
    function menu_userf(user_id, task_users){
        if(user_id){
            for(let x of task_users){
                if(x.user_id == user_id) return x;
            }
            // error if not found?
        }
        else{
            return user_none;
        }
    }


    // const h = {
    //     name: 'create_invitation_modal',
    //     // delegate: ns,
    //     // b: 'DELETE',
    //     // f: "delete_section_from_modal",
    //     // ff: delete_selected,
    //     title: 'Send Invitation',
    //     h: '',
    //     buttons: [
    //         [ 'Send', cbtn, create_invite ]
    //     ]
    // };
    // let email = $state();
    // let role = $state();
    // let project_id = $state();
    // let task_id = $state();
    // function create_invite(){
    //     postp(
    //         "/invites",
    //         {
    //             email: email,
    //             role: role,
    //             task_id: task_id,
    //             project_id: project_id
    //         }
    //       ).then( (data) => {
    //             let flash_value;
    //             if(!data){
    //                 toast.error('bad response');
    //             }
    //             if(data.errors){
    //                 flash_value = data.errors.join(' ');
    //                 toast.error(flash_value);
    //             }
    //             else{
    //                 flash_value = "sent to " + data.invite.email;
    //                 toast.success(flash_value);
    //                 get();
    //             }
    //         }
    //       );
    // }

    // Audio player state and functions
    let audioUrl = $state('');
    let audioSrc = $state('');
    let audioElement = $state();
    let currentFileName = $state('');
    let volume = $state(1.0);
    let playbackRate = $state(1.0);
    let audioError = $state('');
    let recentAudioFiles = $state([]);
    let signedUrl = $state('');
    let urlExpiry = $state('');
    let transcriptionResult = $state('');
    let isTranscribing = $state(false);

    // Load audio file from URL
    async function loadAudioFile() {
        if (!audioUrl.trim()) {
            toast.error('Please enter an audio file URL or blob name');
            return;
        }

        audioError = '';
        signedUrl = '';
        urlExpiry = '';
        const input = audioUrl.trim();
        
        // Check if input is a full URL or just a blob name
        let finalUrl = input;
        let isSignedUrl = false;
        
        try {
            // If it's not a full URL, get signed URL from Rails
            if (!input.startsWith('http')) {
                const response = await fetch(`/azure_audio_url?blob_name=${encodeURIComponent(input)}`, {
                    headers: {
                        'Accept': 'application/json',
                        'X-Requested-With': 'XMLHttpRequest'
                    }
                });
                
                if (!response.ok) {
                    const errorData = await response.json();
                    console.error('Server error details:', errorData);
                    toast.error(`Server Error: ${errorData.error || `HTTP ${response.status}`}`);
                    
                    // Show service class info if available
                    if (errorData.service_class) {
                        console.log('Current service class:', errorData.service_class);
                        toast.info(`Current storage service: ${errorData.service_class}`);
                    }
                    throw new Error(errorData.error || `HTTP ${response.status}`);
                }
                
                const data = await response.json();
                console.log('Server response:', data);
                finalUrl = data.url;
                signedUrl = data.url;
                isSignedUrl = true;
                
                // Calculate expiry time (1 hour from now)
                const expiryTime = new Date();
                expiryTime.setHours(expiryTime.getHours() + 1);
                urlExpiry = expiryTime.toLocaleString();
                
                toast.success(`Generated signed URL for Azure blob (Service: ${data.service_class || 'Unknown'})`);
            } else {
                // If it's already a full URL, check if it's a signed URL
                if (input.includes('sig=')) {
                    signedUrl = input;
                    urlExpiry = 'Unknown expiry';
                }
            }
        } catch (error) {
            console.error('Error getting signed URL:', error);
            toast.error(`Failed to get audio URL: ${error.message}`);
            return;
        }

        audioSrc = finalUrl;
        
        // Extract filename from original input or URL
        try {
            if (input.startsWith('http')) {
                const url = new URL(input);
                const pathname = url.pathname;
                currentFileName = pathname.split('/').pop() || 'Unknown file';
            } else {
                currentFileName = input.split('/').pop() || 'Unknown file';
            }
        } catch (e) {
            currentFileName = input.split('/').pop() || 'Unknown file';
        }

        // Add to recent files (avoid duplicates)
        const existingIndex = recentAudioFiles.findIndex(f => f.originalInput === input);
        if (existingIndex >= 0) {
            recentAudioFiles.splice(existingIndex, 1);
        }
        
        recentAudioFiles.unshift({
            name: currentFileName,
            url: finalUrl,
            originalInput: input,
            timestamp: new Date()
        });

        // Keep only last 10 files
        if (recentAudioFiles.length > 10) {
            recentAudioFiles = recentAudioFiles.slice(0, 10);
        }

        toast.success(`Loading: ${currentFileName}`);
    }

    // Load a recent file
    function loadRecentFile(originalInput) {
        audioUrl = originalInput;
        loadAudioFile();
    }

    // Copy signed URL to clipboard
    async function copySignedUrl() {
        try {
            await navigator.clipboard.writeText(signedUrl);
            toast.success('Signed URL copied to clipboard');
        } catch (error) {
            console.error('Failed to copy to clipboard:', error);
            toast.error('Failed to copy URL to clipboard');
        }
    }

    // Transcribe audio using Azure Speech Services
    async function transcribeAudio() {
        if (!audioUrl.trim()) {
            toast.error('Please load an audio file first');
            return;
        }

        isTranscribing = true;
        transcriptionResult = '';

        try {
            const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
            
            const response = await fetch('/azure_transcribe', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest',
                    'X-CSRF-Token': csrfToken
                },
                body: JSON.stringify({
                    blob_name: audioUrl.trim()
                })
            });

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.error || `HTTP ${response.status}`);
            }

            const data = await response.json();
            transcriptionResult = data.transcription;
            toast.success('Transcription completed!');

        } catch (error) {
            console.error('Transcription error:', error);
            toast.error(`Transcription failed: ${error.message}`);
            transcriptionResult = `Error: ${error.message}`;
        } finally {
            isTranscribing = false;
        }
    }

    // Update volume
    function updateVolume() {
        if (audioElement) {
            audioElement.volume = volume;
        }
    }

    // Update playback rate
    function updatePlaybackRate() {
        if (audioElement) {
            audioElement.playbackRate = playbackRate;
        }
    }

    // Handle audio errors
    $effect(() => {
        if (audioElement) {
            audioElement.addEventListener('error', (e) => {
                console.error('Audio error:', e);
                audioError = 'Failed to load audio file. Please check the URL and ensure the file is accessible.';
                toast.error('Error loading audio file');
            });

            audioElement.addEventListener('loadstart', () => {
                audioError = '';
            });

            audioElement.addEventListener('canplay', () => {
                updateVolume();
                updatePlaybackRate();
                toast.success('Audio loaded successfully');
            });
        }
    });

</script>

<style>
</style>

<Toaster richColors expand={true} />

<Help {help}>
    {#snippet content()}
    <div>
        <p>Help Mode On</p>
        <p>more info can be found on each tab</p>
    </div>
    {/snippet}
</Help>

<div>
    {#if admin}
        <div>
          jump to readonly
          <input class="jtro">
        </div>
    {/if}
</div>

<button class="{btn} bg-blue-200 float-right" onclick={() => help = !help}>Help</button>

{#snippet dialog_create(model)}
    <Dialog.Root>
        <Dialog.Trigger class={buttonVariants({ variant: "secondary" })}>Create {models[model].label}</Dialog.Trigger>
        <Dialog.Content>
            <Dialog.Header>
                <Dialog.Title>Create {models[model].label}</Dialog.Title>
                <Dialog.Description>
                    {models[model].desc}
                </Dialog.Description>
            </Dialog.Header>
            {#if model == 'feature'}
                <Label for="dialog_create_category">Category</Label>
                <Input type="text" id="dialog_create_category" placeholder="Category" />
            {/if}
            <Label for="dialog_create_name">Name</Label>
            <Input type="text" id="dialog_create_name" placeholder="Name" />
            <Dialog.Footer>
                <Button variant="secondary" onclick={actions[model].create}>Create</Button>
            </Dialog.Footer>
        </Dialog.Content>
    </Dialog.Root>
{/snippet}

{#snippet dialog_delete(model)}
    <Dialog.Root>
        <Dialog.Trigger class={buttonVariants({ variant: "secondary" })}>Delete {models[model].label}</Dialog.Trigger>
        <Dialog.Content>
            <Dialog.Header>
                <Dialog.Title>Delete {models[model].label}</Dialog.Title>
                <Dialog.Description>
                    This will delete the {models[model].label} {models[model].index[models[model].id].name}, are you sure you want to do this?
                </Dialog.Description>
            </Dialog.Header>
            <Dialog.Footer>
                <Button variant="destructive" onclick={actions[model].delete}>Delete</Button>
            </Dialog.Footer>
        </Dialog.Content>
    </Dialog.Root>
{/snippet}

{#snippet dialog_create_member(model)}
    <Dialog.Root>
        <Dialog.Trigger class={buttonVariants({ variant: "secondary" })}>Add Member</Dialog.Trigger>
        <Dialog.Content style="width: 800px; max-width: 800px;">
            <Dialog.Header>
                <Dialog.Title>Add Member</Dialog.Title>
                <Dialog.Description>
                    Add User to {models[model].label}
                </Dialog.Description>
            </Dialog.Header>
            <div class="grid grid-cols-2">
                <div>
                    <Label for="dialog_create_member_name">Name</Label>
                    <Input type="text" id="dialog_create_member_name" placeholder="Name" bind:value={member_name} />
                </div>
                <div>
                    {#await memberp}
                        names
                    {:then v}
                        {#each v as x}
                            {#if x.name.includes(member_name)}
                                <button class="{buttonVariants({ variant: "secondary" })} m-2" onclick={() => member_create(model, x)}>{x.name}</button>
                            {/if}
                        {/each}
                    {/await}
                </div>
            </div>
            <!-- <Dialog.Footer>
                <Button variant="secondary" onclick={f}>Create</Button>
            </Dialog.Footer> -->
        </Dialog.Content>
    </Dialog.Root>
{/snippet}

{#snippet dialog_delete_member(model)}
    <Dialog.Root>
        <Dialog.Trigger class={buttonVariants({ variant: "secondary" })}>Remove Member</Dialog.Trigger>
        <Dialog.Content>
            <Dialog.Header>
                <Dialog.Title>Remove Member</Dialog.Title>
                <Dialog.Description>
                    This will remove {models[model].user_index[models[model].user_id].name}, are you sure you want to do this?
                </Dialog.Description>
            </Dialog.Header>
            <Dialog.Footer>
                <Button variant="destructive" onclick={() => member_delete(model)}>Delete</Button>
            </Dialog.Footer>
        </Dialog.Content>
    </Dialog.Root>
{/snippet}

{#snippet boiler1(model)}
    {@render boiler2(model)}
    {#await pp}
        <div class="mx-auto w-8 h-8"><Spinner /></div>
    {:then v}
        {@render boiler4(v)}
        {@render boiler5(model, v)}
    {/await}
{/snippet}

{#snippet boiler2(model)}
    <div class="float-right">
        <button class="{btn}" onclick={() => (pp = null) || actions[model].get_all()}>Return to {models[model].label} list</button>
    </div>
{/snippet}

{#snippet boiler4(v)}
    <div class="float-right p-2">{v.name}</div>
{/snippet}

{#snippet boiler5(model, v)}
    <div class="w-96 mx-auto">
        <div>ID: {v.id}</div>
        {#if model == 'feature'}
            <Patch type="input" urlf={actions[model].patch} label="Category" key="category" value={v.category} />
        {/if}
        {#if model == 'project' && !v.project_owner_bool}
            <div>Name: {name}</div>
        {:else}
            <Patch type="input" urlf={actions[model].patch} label="Name" key="name" value={v.name} />
        {/if}
        {#if model == 'task'}
            {models.task.tab}
            <Patch type="select" urlf={actions[model].patch} label="Status" key="status" value={v.status} values={v.statuses} />
            <Patch type="select" urlf={actions[model].patch} label="Workflow" key="workflow_id" value={v.workflow} values={v.workflows_menu} att="name" />
            <Patch type="select" urlf={actions[model].patch} label="KitType" key="kit_type_id" value={v.kit_type} values={v.kit_types} att="name" />
            <Patch type="select" urlf={actions[model].patch} label="DataSet" key="data_set_id" value={v.data_set} values={v.data_sets} att="name" />
            {#each v.features as x}
                {#if x.name == x.value}
                    <Patch type="checkbox" urlf={actions[model].patch} label={x.label} key={x.name} value={v.constraintb[x.name]} meta="meta" />
                {:else if x.name == '1p_task_id'}
                    <Patch type="select" urlf={actions[model].patch} label={x.label} key={x.name} value={v.menu_task} values={v.menu_tasks} att="name" meta="meta" />
                {:else if x.name == 'docid' || x.name == 'notes' || x.name == 'dual_percentage' || x.name == 'dual_minimum_duration'}
                    <Patch type="input" urlf={actions[model].patch} label={x.label} key={x.name} value={v.constraintb[x.name]} meta="meta" />
                {:else}
                    <Patch type="input" urlf={actions[model].patch} label={x.label} key={x.name} value={v.constraintb[x.name]} />
                {/if}
            {/each}
            <div>
                {#if v.bucket}
                    Bucket {v.bucket} has {v.bucket_size} files
                {:else}
                    no bucket for this task
                {/if}
            </div>
        {/if}
        {#if model == 'kit_type'}
            <Patch type="select" urlf={actions[model].patch} label="Namespace" key="node_class_id" value={v.node_class} values={v.node_classes} att="name" />
            {#each v.features as x}
                {#if x.name == x.value}
                    <Patch type="checkbox" urlf={actions[model].patch} label={x.label} key={x.name} value={v.constraintb[x.name]} meta="constraints" />
                {:else if x.value == 'comma'}
                    <Patch type="input" urlf={actions[model].patch} label={x.label} key={x.name} value={v.constraintb[x.name]} meta="constraints" split="," />
                {:else}
                    <Patch type="input" urlf={actions[model].patch} label={x.label} key={x.name} value={v.constraintb[x.name]} meta="constraints" />
                {/if}
            {/each}
        {:else if model == 'feature'}
            <Patch type="input" urlf={actions[model].patch} label="Value" key="value" value={v.value} />
            <Patch type="input" urlf={actions[model].patch} label="Label" key="label" value={v.label} />
            <Patch type="textarea" urlf={actions[model].patch} label="Description" key="description" value={v.description} textarea={true} />
        {:else if model == 'workflow'}
            <Patch type="textarea" urlf={actions[model].patch} label="Description" key="description" value={v.description} textarea={true} />
            <Patch type="select" urlf={actions[model].patch} label="Type" key="type" value={v.type} values={v.types} />
        {/if}
    </div>
{/snippet}

{#snippet boiler3(model, p1, p2)}
    <div class="flex justify-around">
        <div>{all_label}</div>
        {#if models[model].id && models[model].index}
            <div>
                <button class={buttonVariants({ variant: "secondary" })} onclick={() => actions[model].get_one()}>Open</button>
            </div>
            {@render boiler7(model)}
            {#if p1}
                {@render dialog_delete(model)}
            {/if}
        {:else}
            Select a {models[model].label} in the table for more options.
        {/if}
        {#if p2}
            {@render dialog_create(model)}
        {/if}
    </div>
{/snippet}

{#snippet member_table(model, v, columns)}
    <Table
        indexf={x => models[model].user_index = x}
        {columns}
        rows={v.members}
        selectedf={(x) => selectedfmember(model, x)}
    />
{/snippet}


{#snippet member_tab(model, v)}
    {#if models[model].tab == "members"}
        <div class="flex justify-around">
            <div>Members</div>
            {#if v[model + '_admin_bool']}
                {#if models[model].user_id}
                    {@render dialog_delete_member(model)}
                {/if}
                {@render dialog_create_member(model)}
            {/if}
        </div>
        <div class="flex justify-aroundx p-6">
            <div class="float-leftx col-6 w-1/2">
                {#if model == 'project'}
                    {@render member_table(model, v, [
                        [ 'User ID', 'user_id', 'col-1' ],
                        [ 'Name', 'name', 'col-2' ],
                        [ 'Owner', 'owner', 'col-1' ],
                        [ 'Admin', 'admin', 'col-1' ]
                    ])}
                {:else if model == 'task'}
                    {@render member_table(model, v, [
                        [ 'User ID', 'user_id', 'col-1' ],
                        [ 'Name', 'name', 'col-2' ],
                        [ 'State', 'state', 'col-1' ],
                        [ 'Admin', 'admin', 'col-1' ]
                    ])}
                {:else if model == 'group'}
                    {@render member_table(model, v, [
                        [ 'User ID', 'user_id', 'col-1' ],
                        [ 'Name', 'name', 'col-2' ]
                    ])}
                {/if}
            </div>
            <div class="float-leftx col-6 p-6 w-1/2">
                {#if models[model].user_id && (v.project_owner_bool || v.task_admin_bool)}
                    {#each v.members as x}
                        {#if x.id == models[model].user_id}
                            {#if model == 'project'}
                                <div class="flex items-center space-x-4">
                                    <Patch type="checkbox" urlf={actions[model + '_user'].patch} label="Owner" key="owner" value={x.owner} reload={() => actions[model].get_one('members')} />
                                    <Patch type="checkbox" urlf={actions[model + '_user'].patch} label="Admin" key="admin" value={x.admin} reload={() => actions[model].get_one('members')} />
                                </div>
                            {:else if model == 'task'}
                                <div class="w-1/2">
                                    <Patch type="checkbox"   urlf={actions[model + '_user'].patch} label="Admin" key="admin" value={x.admin} reload={() => actions[model].get_one('members')} />
                                    {#if task_user_states.includes(x.state)}
                                        <Patch type="select" urlf={actions[model + '_user'].patch} label="State" key="state" value={x.state} reload={() => actions[model].get_one('members')} values={task_user_states} />
                                    {:else}
                                        Error
                                    {/if}
                                </div>
                                <div class="my-4">
                                    {#if taskuserpp}
                                        {#await taskuserpp}
                                            <div class="mx-auto w-8 h-8"><Spinner /></div>
                                        {:then v}
                                            <pre>
                                                {v.ok}
                                            </pre>
                                        {/await}
                                    {/if}
                                </div>
                            {/if}
                        {/if}
                    {/each}
                {/if}
            </div>
        </div>
    {/if}
{/snippet}

{#snippet boiler7(model)}
    {#if style}
        <div {style}>
            {#if model == 'project'}
                <div><button class={buttonVariants({ variant: "secondary" })} onclick={() => actions[model].get_one()}>Open Project Info</button></div>
                <div><button class={buttonVariants({ variant: "secondary" })} onclick={() => actions[model].get_one('tasks')}>Open Task List</button></div>
            {:else if model == 'task'}
                <div><button class={buttonVariants({ variant: "secondary" })} onclick={() => actions[model].get_one()}>Open Task Info</button></div>
                <div><button class={buttonVariants({ variant: "secondary" })} onclick={() => actions[model].get_one('kits')}>Open Kit List</button></div>
            {:else}
                <div><button class={buttonVariants({ variant: "secondary" })} onclick={() => actions[model].get_one()}>Open</button></div>
            {/if}
        </div>
    {/if}
{/snippet}

<!-- <PageTabs {pages} {page} on:page={pagef} {admin} {lead_annotator} {help} on:help={helpf} /> -->

<Tabs.Root bind:value={tab} class="w-full justify-center" onValueChange={tabs}>
    <Tabs.List>
        <Tabs.Trigger value="tasks">
            <Tooltip.Provider>
                <Tooltip.Root>
                    <Tooltip.Trigger>Work</Tooltip.Trigger>
                    <Tooltip.Content>your tasks with links to start</Tooltip.Content>
                </Tooltip.Root>
            </Tooltip.Provider>
        </Tabs.Trigger>
        <Tabs.Trigger value="projects">
            <Tooltip.Provider>
                <Tooltip.Root>
                    <Tooltip.Trigger>Projects</Tooltip.Trigger>
                    <Tooltip.Content>projects, tasks, kits</Tooltip.Content>
                </Tooltip.Root>
            </Tooltip.Provider>
        </Tabs.Trigger>
        <Tabs.Trigger value="groups">
            <Tooltip.Provider>
                <Tooltip.Root>
                    <Tooltip.Trigger>Groups</Tooltip.Trigger>
                    <Tooltip.Content>users can be added to groups</Tooltip.Content>
                </Tooltip.Root>
            </Tooltip.Provider>
        </Tabs.Trigger>
        <Tabs.Trigger value="audio">
            <Tooltip.Provider>
                <Tooltip.Root>
                    <Tooltip.Trigger>Audio</Tooltip.Trigger>
                    <Tooltip.Content>play audio files from Azure storage</Tooltip.Content>
                </Tooltip.Root>
            </Tooltip.Provider>
        </Tabs.Trigger>
    </Tabs.List>
    <Tabs.Content value="tasks">
        <Help {help}>
            {#snippet content()}
            <div>
                <p>These are your tasks</p>
                <p>The Action column contains links to annotation tools, if work is available</p>
                <p>Clicking on a Project or Task name will jump to the appropriate tab</p>
            </div>
            {/snippet}
        </Help>
            <!-- <UsersTasks {help} {admin} {lead_annotator} {p} {project} {task} /> -->
        {#await p}
            <div class="mx-auto w-8 h-8"><Spinner /></div>
        {:then v}
            <Table
                indexf={x => null}
                columns={[
                    [ 'Project',   'project', 'col-1', 'f', (x, y) => goto(x, y) ],
                    [ 'Task',      'task',    'col-2', 'f', (x, y) => goto(x, y) ],
                    [ 'Action',    'action',  'col-1', 'html' ],
                    [ 'Status',    'state',   'col-1' ],
                    [ 'Done Kits', 'done',    'col-1' ]
                ]}
                rows={v[0]}
                key_column="task"
                selectedf={() => null}
            />
        {/await}
    </Tabs.Content>
    <Tabs.Content value="projects">
        {#if tab == 'projects'}
            <Help {help}>
                {#snippet content()}
                    <div>
                        <p>Projects contain Tasks, which in turn contain Kits</p>
                        <p>Select and Open a Project from the table</p>
                        {#if lead_annotator}
                            <p>You also have permission to create a new Project</p>
                        {/if}
                    </div>
                {/snippet}
            </Help>
            {#await tabp}
                <div class="mx-auto w-8 h-8"><Spinner /></div>
            {:then v}
                {#if pp}
                    {@render boiler2('project')}
                    {#await pp}
                        <div class="mx-auto w-8 h-8"><Spinner /></div>
                    {:then v}
                        {@render boiler4(v)}
                        <Tabs.Root bind:value={models.project.tab} class="w-full">
                            <Tabs.List>
                                <Tabs.Trigger value="info">Project Info</Tabs.Trigger>
                                <Tabs.Trigger value="tasks">Project Tasks</Tabs.Trigger>
                                <Tabs.Trigger value="members">Project Members</Tabs.Trigger>
                            </Tabs.List>
                            <Tabs.Content value="info">
                                {@render boiler5('project', v)}
                            </Tabs.Content>
                            <Tabs.Content value="tasks">
                                <Help {help}>
                                    {#snippet content()}
                                        <div>
                                            <p>Tasks contain Kits</p>
                                            <p>Select and Open a Task from the table</p>
                                            {#if v.project_admin_bool}
                                                <p>You also have permission to create a new Task</p>
                                            {/if}
                                        </div>
                                    {/snippet}
                                </Help>
                                {#if taskpp}
                                    <div class="float-right">
                                        <button class="{btn}" onclick={() => (taskpp = null) || actions.project.get_one('tasks')}>Return to Task list</button>
                                    </div>
                                    {#await taskpp}
                                        <div class="mx-auto w-8 h-8"><Spinner /></div>
                                    {:then vv}
                                        {#if vv.error}
                                            <div>Error: {vv.error}</div>
                                        {:else}
                                            <div class="float-right p-2">
                                                {vv.name} {vv.id}
                                            </div>
                                            <!-- <Task {help} {project_admin} {project_id} {task_id} {...v} {project_users} reload={open} {info} /> -->
                                            <!-- {task_id} {task_index[task_id].name} -->
                                            <Tabs.Root bind:value={models.task.tab} class="w-full justify-center">
                                                <Tabs.List>
                                                    <Tabs.Trigger value="info">Task Info</Tabs.Trigger>
                                                </Tabs.List>
                                                <Tabs.Content value="info">
                                                    {#if models.task.tab == 'info'}
                                                        {#if v.project_admin_bool}
                                                            {@render boiler5('task', vv)}
                                                        {:else}
                                                            <div class="col-3 mx-auto">
                                                                <div>ID: {vv.id}</div>
                                                                <div>Name: {vv.name}</div>
                                                            </div>
                                                        {/if}
                                                    {/if}
                                                </Tabs.Content>
                                            </Tabs.Root>
                                        {/if}
                                    {/await}
                                {:else}
                                    <div class="flex justify-around items-center my-2">
                                        {#if v.project_admin_bool}
                                            <div class="font-semibold">All Tasks</div>
                                        {:else}
                                            <div class="font-semibold">My Tasks</div>
                                        {/if}
                                        {#if models.task.id && models.task.index}
                                            <div>
                                                <button class={buttonVariants({ variant: "secondary" })} onclick={() => actions.task.get_one()}>Open</button>
                                            </div>
                                            {@render boiler7('task')}
                                            {#if v.project_admin_bool}
                                                {@render dialog_delete('task')}
                                            {/if}
                                        {/if}
                                        {#if v.project_admin_bool}
                                            {@render dialog_create('task')}
                                        {/if}
                                    </div>
                                    <Table
                                        indexf={x => models.task.index = x}
                                        columns={[
                                            [ 'ID', 'id', 'col-1' ],
                                            [ 'Task', 'name', 'col-2' ],
                                            [ 'Available Kits', 'available_kit_count', 'col-1' ],
                                            [ 'Source UID', 'source_uid', 'col-1' ]
                                        ]}
                                        rows={v.tasks}
                                        selectedf={(x, y) => (models.task.id = x) && set_style(y)}
                                    />
                                {/if}
                            </Tabs.Content>
                            <Tabs.Content value="members">
                                {@render member_tab('project', v)}
                            </Tabs.Content>
                        </Tabs.Root>
                    {/await}
                {:else}
                    {@render boiler3("project", admin, lead_annotator)}
                    <Table
                        indexf={x => models.project.index = x}
                        columns={[
                            [ 'ID', 'id', 'col-1' ],
                            [ 'Project', 'name', 'col-2', 'html' ],
                            [ 'Task Count', 'task_count', 'col-1' ]
                        ]}
                        rows={v}
                        selectedf={(x, y) => (models.project.id = x) && set_style(y)}
                    />
                {/if}
            {/await}
        {/if}
    </Tabs.Content>
    <Tabs.Content value="groups">
        {#if tab == 'groups'}
            <Help {help}>
                {#snippet content()}
                <div>
                    <p>groups</p>
                </div>
                {/snippet}
            </Help>
            {#await tabp}
                <div class="mx-auto w-8 h-8"><Spinner /></div>
            {:then v}
                {#if pp}
                    {@render boiler2('group')}
                    {#await pp}
                        <div class="mx-auto w-8 h-8"><Spinner /></div>
                    {:then v}
                        {@render boiler4(v)}
                        <Tabs.Root bind:value={models.group.tab} class="w-full">
                            <Tabs.List>
                                <Tabs.Trigger value="info">Group Info</Tabs.Trigger>
                                <Tabs.Trigger value="members">Group Members</Tabs.Trigger>
                            </Tabs.List>
                            <Tabs.Content value="info">
                                {@render boiler5('group', v)}
                             </Tabs.Content>
                            <Tabs.Content value="members">
                                {@render member_tab('group', v)}
                            </Tabs.Content>
                        </Tabs.Root>
                    {/await}
                {:else}
                    {@render boiler3("group", admin, lead_annotator)}
                    <Table
                        indexf={x => models.group.index = x}
                        columns={[
                            [ 'Name', 'name', 'col-1' ],
                            [ 'Description', 'description', 'col-1' ],
                            [ 'Type', 'type', 'col-1' ],
                        ]}
                        rows={v}
                        selectedf={(x, y) => (models.group.id = x) && set_style(y)}
                    />
                {/if}
            {/await}
        {/if}
    </Tabs.Content>
    <Tabs.Content value="audio">
        <Help {help}>
            {#snippet content()}
            <div>
                <p>Audio Player</p>
                <p>Play audio files stored in your Azure Storage container</p>
                <p>Enter the Azure blob URL or file path to play audio files</p>
            </div>
            {/snippet}
        </Help>
        <div class="max-w-4xl mx-auto p-6">
            <div class="mb-6">
                <h2 class="text-2xl font-bold mb-4">Azure Audio Player</h2>
                <div class="space-y-4">
                    <div>
                        <Label for="azure-audio-url">Azure Audio File URL or Path</Label>
                        <div class="flex space-x-2 mt-2">
                            <Input 
                                type="text" 
                                id="azure-audio-url" 
                                bind:value={audioUrl}
                                placeholder="audio/filename.mp3 or full Azure URL"
                                class="flex-1"
                            />
                            <Button onclick={loadAudioFile} variant="secondary">Load</Button>
                        </div>
                        <div class="text-sm text-gray-600 mt-1">
                            Enter either a blob name (e.g., "audio/file.mp3") or a full Azure URL
                        </div>
                    </div>
                    
                    {#if audioSrc}
                        <div class="border rounded-lg p-4 bg-gray-50">
                            <h3 class="text-lg font-semibold mb-3">Now Playing: {currentFileName}</h3>
                            
                            {#if signedUrl}
                                <div class="mb-4 p-3 bg-blue-50 border border-blue-200 rounded">
                                    <div class="flex justify-between items-start mb-2">
                                        <span class="text-sm font-medium text-blue-800">Signed URL:</span>
                                        <Button 
                                            onclick={copySignedUrl}
                                            variant="outline" 
                                            size="sm"
                                            class="h-6 px-2 text-xs"
                                        >
                                            Copy
                                        </Button>
                                    </div>
                                    <div class="text-xs text-blue-700 font-mono break-all bg-white p-2 rounded border">
                                        {signedUrl}
                                    </div>
                                    <div class="text-xs text-blue-600 mt-1">
                                        Expires: {urlExpiry || 'in 1 hour'}
                                    </div>
                                </div>
                            {/if}
                            <audio 
                                bind:this={audioElement}
                                controls 
                                class="w-full"
                                preload="metadata"
                            >
                                <source src={audioSrc} type="audio/mpeg" />
                                <source src={audioSrc} type="audio/wav" />
                                <source src={audioSrc} type="audio/ogg" />
                                Your browser does not support the audio element.
                            </audio>
                            
                            <div class="mt-4 space-y-2">
                                <div class="flex justify-between items-center">
                                    <span class="text-sm text-gray-600">Volume</span>
                                    <input 
                                        type="range" 
                                        min="0" 
                                        max="1" 
                                        step="0.1" 
                                        bind:value={volume}
                                        onchange={updateVolume}
                                        class="w-32"
                                    />
                                </div>
                                
                                <div class="flex justify-between items-center">
                                    <span class="text-sm text-gray-600">Playback Speed</span>
                                    <select bind:value={playbackRate} onchange={updatePlaybackRate} class="border rounded px-2 py-1">
                                        <option value="0.5">0.5x</option>
                                        <option value="0.75">0.75x</option>
                                        <option value="1">1x</option>
                                        <option value="1.25">1.25x</option>
                                        <option value="1.5">1.5x</option>
                                        <option value="2">2x</option>
                                    </select>
                                </div>
                                
                                <div class="flex justify-center mt-4">
                                    <Button 
                                        onclick={transcribeAudio}
                                        disabled={isTranscribing}
                                        variant="default"
                                        class="px-6"
                                    >
                                        {#if isTranscribing}
                                            <div class="flex items-center">
                                                <div class="w-4 h-4 mr-2"><Spinner /></div>
                                                Transcribing...
                                            </div>
                                        {:else}
                                            🎤 Transcribe Audio
                                        {/if}
                                    </Button>
                                </div>
                            </div>
                            
                            {#if audioError}
                                <div class="mt-3 p-3 bg-red-100 border border-red-400 text-red-700 rounded">
                                    Error loading audio: {audioError}
                                </div>
                            {/if}
                            
                            {#if transcriptionResult}
                                <div class="mt-4 p-4 bg-green-50 border border-green-200 rounded">
                                    <div class="flex justify-between items-start mb-2">
                                        <h4 class="text-lg font-semibold text-green-800">Transcription Result</h4>
                                        <Button 
                                            onclick={() => navigator.clipboard.writeText(transcriptionResult)}
                                            variant="outline" 
                                            size="sm"
                                            class="h-6 px-2 text-xs"
                                        >
                                            Copy
                                        </Button>
                                    </div>
                                    <div class="text-sm text-green-700 bg-white p-3 rounded border max-h-48 overflow-y-auto">
                                        {transcriptionResult}
                                    </div>
                                </div>
                            {/if}
                        </div>
                    {/if}
                    
                    <div class="border rounded-lg p-4">
                        <h3 class="text-lg font-semibold mb-3">Recent Audio Files</h3>
                        {#if recentAudioFiles.length > 0}
                            <div class="space-y-2">
                                {#each recentAudioFiles as file}
                                    <div class="flex justify-between items-center p-2 border rounded hover:bg-gray-50">
                                        <span class="text-sm truncate flex-1 mr-2">{file.name}</span>
                                        <Button 
                                            onclick={() => loadRecentFile(file.originalInput)}
                                            variant="outline"
                                            size="sm"
                                        >
                                            Play
                                        </Button>
                                    </div>
                                {/each}
                            </div>
                        {:else}
                            <p class="text-gray-500 text-sm">No recent audio files</p>
                        {/if}
                    </div>
                </div>
            </div>
        </div>
    </Tabs.Content>
</Tabs.Root>

