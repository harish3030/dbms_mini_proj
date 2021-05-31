const passport = require('passport');
const nodeGeocoder = require('node-geocoder');
let options = {
    provider: 'openstreetmap'
};
   
let geoCoder = nodeGeocoder(options);

exports.bsignup=function(req,res){
    var message='';
    if(req.method=="POST"){
    const {name,password,license,state,city,cat,contact,address,website}=req.body;
    var hash_v;
    let id;
    db.query("SELECT MAX(BloodBankID) as bbid FROM blood_bank;",(err,result,fields)=>{
        if(err){
            console.log(err);
            res.end(err['sqlMessage']);
        }
        id=result[0].bbid+1;
        console.log(id,"created");
        bcrypt.genSalt(10, function(err, salt) {
            bcrypt.hash(password, null, null, function(err, hash) {
                    hash_v=hash;
                    var location=address+","+city+","+state+","+"India";
                    console.log(location);
                    var lat,longit;
                    geoCoder.geocode(location)
                    .then((ress)=> {
                        console.log(ress[0].latitude,ress[0].longitude);
                        lat=ress[0].latitude;
                        longit=ress[0].longitude;
                        db.query("INSERT INTO blood_bank Values ("+mysql.escape(id)+","+mysql.escape(hash_v)+","+mysql.escape(name)+","+mysql.escape(cat)+","+mysql.escape(address)+","+mysql.escape(contact)+","+mysql.escape(license)+","+mysql.escape(website)+","+mysql.escape(state)+","+mysql.escape(city)+","+mysql.escape(lat)+","+mysql.escape(longit)+");",(err,result,fields)=>{
                        if(err){
                            console.log(err);
                            res.end(err['sqlMessage']);
                        }
                        message = "Your account has been created succesfully.";
                        res.render('bmsg.ejs',{message: message,id:id});
                        //res.end(1);
                    });
                    })
                    .catch((err)=> {
                        console.log(err);
                    })
            });
        });
        });
    }
    else{
        res.render('bsignup.ejs',{message:message});
    }
    
};

exports.blogin=function(req,res,next){
    if(req.method=="POST"){
        var message='';     
        passport.authenticate('bbank', (err, user, info) => {
            req.login(user, (err) => {
              if(req.user){
                console.log(`req.user: ${JSON.stringify(req.user)}`)
                console.log("here");
                req.session.save(() => {
                    res.redirect('/bprofile');
                  })
              }
              else if(!req.user && info.id=="no"){
                message=info.message;
                 console.log(message);
                 res.redirect('/bsignup?error=' + encodeURIComponent(message));
                 
 
               }
               else{
                    // message=info.message;
                     res.render('blogin.ejs', {message: ''} );
                    
               }
            })
          })(req, res, next);
        }
    else{
        console.log('Inside GET /login callback')
        console.log(req.sessionID)
        res.render('blogin.ejs',{message:''});
    }
};

exports.bdashboard=function(req,res){
    //console.log(req.user.BloodBankID);
    if(req.isAuthenticated()) {
        const id=req.user.BloodBankID;
        console.log(id);
        res.render('bbank_dashboard.ejs');
      } 
      else {
        res.redirect('/blogin?error=' + encodeURIComponent('Not logged in'));
      }
}; 



exports.campreg=function(req,res){
    if(req.method=="POST"){
        const {state,city,date}=req.body;
        db.query("SELECT MAX(CampID) as cid from CAMPS",(err,result,field)=>{
            if(err){
                console.log(err);
                res.end(err['sqlMessage']);
            }
            var cid,bid;
            if(!result.length){
                cid=1;
            }
            cid=result[0].cid+1;
            bid=req.user.BloodBankID;
            status="Pending";
            db.query("INSERT INTO CAMPS VALUES("+mysql.escape(cid)+","+mysql.escape(bid)+","+mysql.escape(date)+","+mysql.escape(status)+","+mysql.escape(city)+","+mysql.escape(state)+");",(err,result,fields)=>{
                if(err){
                    console.log(err);
                    res.end(err['sqlMessage']);
                }
                message = "Camp registered";
                //res.render('msg.ejs',{message: message});//change to flash message
                res.redirect('/bprofile?msg=' + encodeURIComponent('Camp registered'));
                return;
            });
        });
    }
    else{
        if(req.isAuthenticated()) {
            const id=req.user.BloodBankID;
            found=1;
            console.log('blood bank id is',id);
            var message='';
            res.render('campreg.ejs');
            
        }
        else {
            res.redirect('/blogin?error=' + encodeURIComponent('Not logged in'));
            return;    
        }
      
       
   }
};

exports.bdonations=function(req,res){
    var found=0;
    if(req.method=="GET"){
        if(req.isAuthenticated()) {           
            const id=req.user.BloodBankID;
            found=1;
        } 
        else {
            res.redirect('/blogin?error=' + encodeURIComponent('Not logged in'));
            return;
        }
    }
    if(found==1){
            let bbid=req.user.BloodBankID; 
            db.query("SELECT * FROM DONATIONS WHERE BloodBankID="+mysql.escape(bbid)+" AND status='Pending';" ,(err,result,field)=>{
            if(err){
                console.log(err);
                res.end(err['sqlMessage']);
            }
            if(result.length){
               // res.send(result);
               res.render('donate_disp.ejs',{data:result});
                  //display static page of donations list     
                  //function to loop through donations and if data matches update availability status
                  // donation status
            }
            else{
                res.redirect('/bprofile?msg=' + encodeURIComponent('No pending donations'));
            }
        });
    } 
};

exports.bcomp_donations=function(req,res){
    var found=0;
    if(req.method=="POST"){
        if(req.isAuthenticated()) {           
            const id=req.user.BloodBankID;
            found=1;
        } 
        else {
            res.redirect('/blogin?error=' + encodeURIComponent('Not logged in'));
            return;
        }
        if(found==1){
            let bid=req.user.BloodBankID;
            console.log(req.user);
            let did=req.params.id;
            let units=req.body.units;//input from form
            let comp=req.body.comp;//input from form
            db.query("CALL UPDATE_DONATIONS("+mysql.escape(did)+","+mysql.escape(bid)+","+mysql.escape(units)+","+mysql.escape(comp)+");",(err,result,fields)=>{
                if(err){
                    console.log(err);
                    res.end(err['sqlMessage']);
                }
                console.log("Donation completed success");//flash
                res.redirect('/bprofile?msg=' + encodeURIComponent('Donation completed success'));
            });
    }
  }
};

exports.bserve_requests=function(req,res){
    var found=0;
    if(req.method=="GET"){
        if(req.isAuthenticated()) {           
            const id=req.user.BloodBankID;
            found=1;
        } 
        else {
            res.redirect('/blogin?error=' + encodeURIComponent('Not logged in'));
            return;
        }
        if(found==1){
            var bbid=req.user.BloodBankID;
            db.query("SELECT SERVE_REG("+mysql.escape(bbid)+") as n_req;",(err,resu,fields)=>{
            if(err){
                console.log(err);
                res.end(err['sqlMessage']);

            }
            if(resu[0].n_req==0){
                res.send("Sorry,No request could be served!")
            }
            else{
                message=resu[0].n_req+"request served";
                console.log(resu[0].n_req+"requests served");
                //res.send(resu[0].n_req+"requests served");//flash
                res.redirect('/bprofile?msg=' + encodeURIComponent(message));
            }
        });
        //function to loop through requests and see if it can be served. Simulatneously trigger to decrease availablity status and 
        // request status
        //trigger to insert in Transactions tab
        //res.send("No pending requests!");
        }        
    }
};

exports.brequests=function(req,res){

    //display static page of requests
    var found=0;
    if(req.method=="GET"){
        if(req.isAuthenticated()) {           
            const id=req.user.BloodBankID;
            found=1;     
        } 
        else {
            res.redirect('/blogin?error=' + encodeURIComponent('Not logged in'));
            return;
        }
        if(found==1){
            let bbid=req.user.BloodBankID;
            db.query("SELECT * FROM Requests WHERE BloodBankID="+mysql.escape(bbid)+" AND Status='Pending';",(err,result,field)=>{
            if(err){
                console.log(err);
                res.end(err['sqlMessage']);
            }
            if(result.length){        
                console.log(result);
                res.render('req_disp.ejs',{data:result});
                  //display static page of donations list
                  //function to loop through donations and if data matches update availability status
                  // donation status   
            }
            else{
                res.redirect('/bprofile?msg=' + encodeURIComponent('No pending requests'));
            }
          
        });
    }
}   
};

exports.bavailable=function(req,res){
    var found=0;
    if(req.method=="GET"){
        if(req.isAuthenticated()) {
             const id=req.user.BloodBankID;
             found=1;
         } 
         else {
            res.redirect('/blogin?error=' + encodeURIComponent('Not logged in'));
             return;
         }
         if(found==1){
          let bid=req.user.BloodBankID;
          //console.log(bid);
          db.query("SELECT B_AVAIL("+mysql.escape(bid)+")as avail;",(err,result,fields)=>{
            if(err){
                console.log(err);
                res.end(err['sqlMessage']);
            }
           //res.render('avail_disp.ejs',{data:result});
            //res.send(result);
            if(result[0].avail==null){
                res.redirect('/bprofile?msg=' + encodeURIComponent('No available blood'));
                return;
            }
            else{
                console.log(result[0].avail);
                res.render('avail_disp.ejs',{data:JSON.parse(result[0].avail)});
            }
            //res.send(typeof(JSON.parse(result[0].avail)));
        });
    }
  }
};

exports.blogout=function(req,res){
    if(req.isAuthenticated()){
      req.session.destroy(function(err) {
           return res.redirect('/blogin');
       })
    }
    else{
        res.redirect('/blogin?error=' + encodeURIComponent('Not logged in'));
        return;
    }
 };