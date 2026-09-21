 import 'package:flutter/material.dart';
import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/pricing_card.dart';
import 'package:forfood/utilities/page_transition.dart';
import 'package:forfood/view/restaurant/home_page.dart';

class SusbscriptionAtBeginingView extends StatefulWidget {
  const SusbscriptionAtBeginingView({super.key});

  @override
  State<SusbscriptionAtBeginingView> createState() => _SusbscriptionAtBeginingViewState();
}

class _SusbscriptionAtBeginingViewState extends State<SusbscriptionAtBeginingView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(


      body:       // Figma Flutter Generator 2dsubscriptionWidget - COMPONENT
      Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColor.yellow,

          child: Column(
           
                  children: [
                    const SizedBox(height: 80),
                    Row(
                      children: [
                        const SizedBox( width : 35 ), 
                    InkWell(
                        onTap: () {
                    
                    
                                  // ✅ Dispatch back event
                         Navigator.pop(context);
                    
                    
                    
                    
                        },
                        child: Image.asset(
                          'assets/icons/BackiconArrow.png',
                          width: 20,
                          height: 20,
                          fit: BoxFit.contain,
                        ),
                      ),
                    
                      ],
                    ),
             
              const SizedBox(height: 25),

              // Circle-with-dot icon
              Container(
                width: 150, height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColor.orange, width: 6),
                ),
                child: Align(
                  alignment:Alignment.centerLeft ,
                  child: Container(
                    width: 14, height: 14,
                    margin: const EdgeInsets.only(left: 15),
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColor.orange),
                  ),
                ),
              ),

        
        
        
              const SizedBox(height: 25),
        
     
        Text('Get your restaurant on ForFood', textAlign: TextAlign.left, style: TextStyle(
        color:AppColor.brown,
        fontFamily: 'Inter',
        fontSize: 22,
        letterSpacing: 0 /*percentages not used in flutter. defaulting to zero*/,
        fontWeight: FontWeight.w700,
        height: 1
      ),),
      
      
     const SizedBox(height: 25),
       
      
     Padding(
       padding: const EdgeInsets.all(8.0),
       child: Text('Try it free for 6 months. Reach customers searching for food that fits their budget, nearby'
, textAlign: TextAlign.center, style: TextStyle(
          color: AppColor.brown,
          fontFamily: 'League Spartan',
          fontSize: 14,
          letterSpacing: 0 /*percentages not used in flutter. defaulting to zero*/,
          fontWeight: FontWeight.bold,
          height: 1
        ),),
     ),
      
   const SizedBox(height: 40 ),



            
  PricingCard(
    planName: 'Yearly',
    subtitle: '   6 months free , then 40\$/yr',
    price: '\$40',
    onTap: () {
      // here it go to payment 
      }, 
    perMonthYear: '/yr',
  ),
     const SizedBox(height: 25 ),

 PricingCard(
    planName: 'Monthly',
    subtitle: '   6 months free , then 5\$/mo',
    price: '\$5',
    onTap: () {
                  // here go to payment 

    }, 
    perMonthYear: '/mo',
  ),

      
          const SizedBox(height: 30 ),

      
     GestureDetector(
          onTap: () {
            Navigator.of(context).push(

              fadeSlideRoute( const RestaurantHomeView()
              )
            ) ;
          },
          child: Container(
  width: 351,
  height: 60,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(26),
    color: AppColor.orange,
  ),
  child: Stack(
    children: [
      Positioned(
        top: 20,    // ← adjust to nudge vertically within the 60-height button
        left: 100,  // ← adjust to nudge horizontally within the 351-width button
        child:  Text(
          'Start Free Trial',
          style: TextStyle(
            color: AppColor.brown,
            fontFamily: 'League Spartan',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1,
          ),
        ),
      ),
    ],
  ),
),
      ),  
      
      
         const SizedBox(height: 30 ),

       Text('No charge for 6 months. Cancel anytime before your trial ends. Subscription auto-renews unless cancelled'
, textAlign: TextAlign.center, style: TextStyle(
        color: AppColor.brown,
        fontFamily: 'League Spartan',
        fontSize: 12,
        letterSpacing: 0 /*percentages not used in flutter. defaulting to zero*/,
        fontWeight: FontWeight.w300,
        height: 1
      ),),
      
      
            const SizedBox(height: 55 ),

     Center(
       child: Text('Terms of Service          Privacy Policy', textAlign: TextAlign.center, style: TextStyle(
          color: AppColor.brown,
          fontFamily: 'League Spartan',
          fontSize: 10,
          letterSpacing: 0 /*percentages not used in flutter. defaulting to zero*/,
          fontWeight: FontWeight.w300,
          height: 1
        ),),
     ),
      
      
      
      
    
      
      
 
      
      
      

    
      
      
            ],
                ),
              ),
        
      );
  
  }
}